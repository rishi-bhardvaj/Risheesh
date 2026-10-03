import { v4 as uuidv4 } from 'uuid';
import { query } from '../../db';
import type { MatchResult, NormalizedJob, SyncSummary } from './types';

export const LOCK_NAME = 'jobs_hourly_sync';
export const RUN_DATA_TYPE = 'jobs_sync';

export type UpsertOutcome = 'inserted' | 'updated' | 'duplicate';

interface ExistingRow {
  id: string;
  source: string | null;
  content_hash: string | null;
  title: string;
  location: string | null;
  status: string;
  match_score: string | null;
  level: number;
}

const UNIQUE_VIOLATION = '23505';

export class JobSyncRepository {
  // ---- Lock --------------------------------------------------------------------------------
  /**
   * Lease lock in a table (atomic INSERT .. ON CONFLICT .. WHERE expired). Unlike session
   * advisory locks it survives connection pooling (Neon/PgBouncer) and expires on its own
   * if the holder crashes.
   */
  async acquireLock(owner: string, ttlSeconds: number): Promise<boolean> {
    const res = await query(
      `INSERT INTO job_sync_locks (name, owner, locked_until)
       VALUES ($1, $2, NOW() + ($3 || ' seconds')::interval)
       ON CONFLICT (name) DO UPDATE
         SET owner = EXCLUDED.owner, locked_until = EXCLUDED.locked_until, acquired_at = NOW()
         WHERE job_sync_locks.locked_until < NOW()
       RETURNING owner`,
      [LOCK_NAME, owner, String(ttlSeconds)]
    );
    return (res.rowCount ?? 0) === 1 && res.rows[0].owner === owner;
  }

  async renewLock(owner: string, ttlSeconds: number): Promise<boolean> {
    const res = await query(
      `UPDATE job_sync_locks SET locked_until = NOW() + ($3 || ' seconds')::interval
       WHERE name = $1 AND owner = $2`,
      [LOCK_NAME, owner, String(ttlSeconds)]
    );
    return (res.rowCount ?? 0) === 1;
  }

  async releaseLock(owner: string): Promise<void> {
    await query('DELETE FROM job_sync_locks WHERE name = $1 AND owner = $2', [LOCK_NAME, owner]);
  }

  // ---- Runs (reuses import_runs) -------------------------------------------------------------
  async abandonStaleRuns(): Promise<number> {
    // Called only while holding the lock, so any IN_PROGRESS sync run is a crashed predecessor.
    const res = await query(
      `UPDATE import_runs SET status = 'FAILED', completed_at = NOW(),
              error_message = 'Run abandoned (process stopped before completion)'
       WHERE data_type = $1 AND status = 'IN_PROGRESS'`,
      [RUN_DATA_TYPE]
    );
    return res.rowCount ?? 0;
  }

  async createRun(trigger: string): Promise<string> {
    const id = uuidv4();
    await query(
      `INSERT INTO import_runs (id, data_type, source, status, metadata)
       VALUES ($1, $2, 'hourly-sync', 'IN_PROGRESS', $3::jsonb)`,
      [id, RUN_DATA_TYPE, JSON.stringify({ trigger })]
    );
    return id;
  }

  async finishRun(id: string, s: SyncSummary): Promise<void> {
    await query(
      `UPDATE import_runs SET status = $2, completed_at = NOW(), received_count = $3, inserted_count = $4,
              updated_count = $5, duplicate_count = $6, rejected_count = $7, error_message = $8,
              metadata = metadata || $9::jsonb
       WHERE id = $1`,
      [
        id,
        s.status,
        s.jobsDiscovered,
        s.jobsInserted,
        s.jobsUpdated,
        s.jobsDeduplicated,
        s.jobsRejected,
        s.errorSummary,
        JSON.stringify({
          providersAttempted: s.providersAttempted,
          providersSucceeded: s.providersSucceeded,
          providersFailed: s.providersFailed,
          jobsSkipped: s.jobsSkipped,
          jobsMarkedStale: s.jobsMarkedStale,
          jobsMarkedClosed: s.jobsMarkedClosed,
          rejectionReasons: s.rejectionReasons,
          providers: s.providers,
        }),
      ]
    );
  }

  async latestRun(onlyCompleted = false) {
    const res = await query(
      `SELECT id, status, started_at, completed_at, received_count, inserted_count, updated_count,
              duplicate_count, rejected_count, error_message, metadata
       FROM import_runs
       WHERE data_type = $1 ${onlyCompleted ? "AND status IN ('SUCCESS','PARTIAL_SUCCESS')" : ''}
       ORDER BY started_at DESC LIMIT 1`,
      [RUN_DATA_TYPE]
    );
    return res.rows[0] ?? null;
  }

  async recentRuns(limit = 10) {
    const res = await query(
      `SELECT id, status, started_at, completed_at, received_count, inserted_count, updated_count,
              duplicate_count, rejected_count, error_message
       FROM import_runs WHERE data_type = $1 ORDER BY started_at DESC LIMIT $2`,
      [RUN_DATA_TYPE, limit]
    );
    return res.rows;
  }

  async statusCounts(): Promise<Record<string, number>> {
    const res = await query('SELECT status, COUNT(*)::int AS n FROM jobs GROUP BY status');
    return Object.fromEntries(res.rows.map((r: { status: string; n: number }) => [r.status, r.n]));
  }

  // ---- Persistence + deduplication -----------------------------------------------------------
  /**
   * Dedupe order: (1) source+external_id, (2) canonical URL, (3) company+title+location key,
   * (4) content fingerprint (same company + long description, and same title or location). Lower level wins.
   */
  async findExisting(job: NormalizedJob): Promise<ExistingRow | null> {
    const fingerprint = job.description && job.description.length >= 200 ? job.contentHash : null;
    const res = await query<ExistingRow>(
      `SELECT id, source, content_hash, title, location, status, match_score,
              CASE WHEN source = $1 AND external_id = $2 THEN 1
                   WHEN canonical_url = $3 THEN 2
                   WHEN dedupe_key IS NOT NULL AND dedupe_key = $4 THEN 3
                   ELSE 4 END AS level
       FROM jobs
       WHERE (source = $1 AND external_id = $2)
          OR canonical_url = $3
          OR ($4::text IS NOT NULL AND dedupe_key = $4)
          OR ($5::text IS NOT NULL AND content_hash = $5 AND LOWER(company) = LOWER($6)
              AND (LOWER(title) = LOWER($7) OR LOWER(COALESCE(location, '')) = LOWER($8)))
       ORDER BY level, created_at
       LIMIT 1`,
      [job.source, job.externalId, job.canonicalUrl, job.dedupeKey, fingerprint, job.company, job.title, job.location ?? '']
    );
    return res.rows[0] ?? null;
  }

  async upsert(job: NormalizedJob, match: MatchResult): Promise<UpsertOutcome> {
    const existing = await this.findExisting(job);
    if (existing) return this.refresh(existing, job, match);

    const inserted = await query(
      `INSERT INTO jobs (
         id, external_id, title, company, location, salary, employment_type, experience_requirement,
         url, source, description, skills, posted_date, discovered_at, match_score, match_reason,
         is_saved, metadata, canonical_url, dedupe_key, content_hash, last_seen_at, status, created_at, updated_at
       ) VALUES (
         $1, $2, $3, $4, $5, $6, $7, $8,
         $9, $10, $11, $12::jsonb, $13, NOW(), $14, $15,
         FALSE, $16::jsonb, $17, $18, $19, NOW(), 'OPEN', NOW(), NOW()
       )
       ON CONFLICT DO NOTHING
       RETURNING id`,
      [
        uuidv4(),
        job.externalId,
        job.title,
        job.company,
        job.location,
        job.salary,
        job.employmentType ?? (job.isRemote ? 'Remote' : 'Full-time'),
        match.experienceRequirement,
        job.url,
        job.source,
        job.description,
        JSON.stringify(Array.from(new Set([...match.matchedSkills, ...job.skills])).slice(0, 40)),
        job.postedAt,
        match.score,
        match.reason,
        JSON.stringify(job.metadata),
        job.canonicalUrl,
        job.dedupeKey,
        job.contentHash,
      ]
    );
    if ((inserted.rowCount ?? 0) === 1) return 'inserted';

    // A concurrent writer (or an index we did not probe) won the race: treat as duplicate.
    const raced = await this.findExisting(job);
    if (raced) return this.refresh(raced, job, match);
    return 'duplicate';
  }

  private async refresh(existing: ExistingRow, job: NormalizedJob, match: MatchResult): Promise<UpsertOutcome> {
    // Only the provider that owns the row may rewrite its content; cross-source copies are no-ops.
    if (existing.source !== job.source) return 'duplicate';

    const changed =
      existing.content_hash !== job.contentHash ||
      existing.title !== job.title ||
      (existing.location ?? null) !== job.location ||
      existing.status !== 'OPEN' ||
      Number(existing.match_score) !== match.score;

    if (!changed) {
      await query('UPDATE jobs SET last_seen_at = NOW() WHERE id = $1', [existing.id]);
      return 'duplicate';
    }

    const params = [
      existing.id,
      job.title,
      job.company,
      job.location,
      job.salary,
      job.employmentType ?? (job.isRemote ? 'Remote' : 'Full-time'),
      match.experienceRequirement,
      job.description,
      JSON.stringify(Array.from(new Set([...match.matchedSkills, ...job.skills])).slice(0, 40)),
      job.postedAt,
      match.score,
      match.reason,
      job.contentHash,
    ];
    const base = `UPDATE jobs SET title = $2, company = $3, location = $4, salary = $5, employment_type = $6,
        experience_requirement = $7, description = $8, skills = $9::jsonb, posted_date = COALESCE($10, posted_date),
        match_score = $11, match_reason = $12, content_hash = $13, last_seen_at = NOW(), status = 'OPEN',
        updated_at = NOW()`;
    try {
      // Backfill keys on rows created before migration 005, when they do not collide.
      await query(`${base}, canonical_url = COALESCE(canonical_url, $14), dedupe_key = COALESCE(dedupe_key, $15) WHERE id = $1`, [
        ...params,
        job.canonicalUrl,
        job.dedupeKey,
      ]);
    } catch (err) {
      if ((err as { code?: string }).code !== UNIQUE_VIOLATION) throw err;
      await query(`${base} WHERE id = $1`, params);
    }
    return 'updated';
  }

  // ---- Freshness -----------------------------------------------------------------------------
  /** OPEN -> STALE after staleAfterHours unseen; STALE -> CLOSED after closeAfterDays. Never deletes. */
  async applyFreshness(sources: string[], staleAfterHours: number, closeAfterDays: number) {
    if (sources.length === 0) return { stale: 0, closed: 0 };
    const stale = await query(
      `UPDATE jobs SET status = 'STALE', updated_at = NOW()
       WHERE status = 'OPEN' AND source = ANY($1::text[]) AND last_seen_at IS NOT NULL
         AND last_seen_at < NOW() - ($2 || ' hours')::interval`,
      [sources, String(staleAfterHours)]
    );
    const closed = await query(
      `UPDATE jobs SET status = 'CLOSED', updated_at = NOW()
       WHERE status IN ('OPEN','STALE') AND source = ANY($1::text[]) AND last_seen_at IS NOT NULL
         AND last_seen_at < NOW() - ($2 || ' days')::interval`,
      [sources, String(closeAfterDays)]
    );
    return { stale: stale.rowCount ?? 0, closed: closed.rowCount ?? 0 };
  }
}

export const jobSyncRepository = new JobSyncRepository();
