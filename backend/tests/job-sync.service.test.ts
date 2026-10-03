import { randomUUID } from 'crypto';
import { config } from '../src/config';
import { pool, query } from '../src/db';
import { HttpClient } from '../src/modules/job-sync/http';
import { loadJobSyncConfig } from '../src/modules/job-sync/job-sync.config';
import { normalizeJob } from '../src/modules/job-sync/job-normalization.service';
import { JobMatchingService } from '../src/modules/job-sync/job-matching.service';
import { jobSyncRepository as repo, LOCK_NAME } from '../src/modules/job-sync/job-sync.repository';
import { checkSchema } from '../src/modules/job-sync/job-sync.health';
import { JobSyncService } from '../src/modules/job-sync/job-sync.service';
import { ALLOWED_HOSTS } from '../src/modules/job-sync/providers';
import { leverProvider } from '../src/modules/job-sync/providers/lever.provider';
import type { JobProvider, RawJob } from '../src/modules/job-sync/types';
import { redact } from '../src/utils/logger';
import fs from 'fs';
import path from 'path';

const cfg = loadJobSyncConfig({ JOB_SYNC_BOARD_DELAY_MS: '0' } as unknown as NodeJS.ProcessEnv);
const matcher = new JobMatchingService(cfg);

const raw = (n: number, over: Partial<RawJob> = {}): RawJob => ({
  source: 'ignored',
  externalId: `ext-${n}`,
  url: `https://jobs.example.com/${n}`,
  title: `Backend Engineer ${String.fromCharCode(64 + n)}`, // distinct titles so level-3 keys differ
  company: 'Acme',
  location: 'Bengaluru, India',
  description: `Build REST APIs with Java, Spring Boot and PostgreSQL (role ${n}). 0-2 years experience.`,
  ...over,
});

const provider = (id: string, source: string, jobs: RawJob[] | Error, delayMs = 0): JobProvider => ({
  id,
  source,
  fetchJobs: async () => {
    if (delayMs) await new Promise((r) => setTimeout(r, delayMs));
    if (jobs instanceof Error) throw jobs;
    return { jobs, boardsAttempted: 1, boardsFailed: 0, errors: [] };
  },
});

const svc = (providers: JobProvider[]) => new JobSyncService({ cfg, providers });
const count = async (where = "source LIKE 'TestSync%'") => Number((await query(`SELECT COUNT(*) AS n FROM jobs WHERE ${where}`)).rows[0].n);

async function cleanup() {
  // The Lever e2e test uses the real provider source, so also remove its fixture URLs.
  await query("DELETE FROM jobs WHERE source LIKE 'TestSync%' OR canonical_url LIKE 'https://jobs.lever.co/x/%'");
  await query("DELETE FROM import_runs WHERE data_type = 'jobs_sync'");
  await query('DELETE FROM job_sync_locks WHERE name = $1', [LOCK_NAME]);
}

beforeEach(cleanup);
afterAll(async () => {
  await cleanup();
  await pool.end();
});

describe('sync: provider outcomes', () => {
  it('all providers succeed -> SUCCESS, rows persisted with freshness + dedupe keys', async () => {
    const s = await svc([
      provider('a', 'TestSync-A', [raw(1), raw(2)]),
      provider('b', 'TestSync-B', [raw(3, { url: 'https://jobs.example.com/b3', company: 'Other' })]),
    ]).run({ trigger: 'test' });

    expect(s.status).toBe('SUCCESS');
    expect(s).toMatchObject({ providersAttempted: 2, providersSucceeded: 2, providersFailed: 0, jobsDiscovered: 3, jobsInserted: 3, jobsRejected: 0 });
    const rows = (await query("SELECT * FROM jobs WHERE source LIKE 'TestSync%' ORDER BY title")).rows;
    expect(rows).toHaveLength(3);
    for (const r of rows) {
      expect(r.status).toBe('OPEN');
      expect(r.last_seen_at).not.toBeNull();
      expect(r.canonical_url).toMatch(/^https:\/\//);
      expect(r.dedupe_key).toContain('|');
      expect(Number(r.match_score)).toBeGreaterThanOrEqual(cfg.minMatchScore);
      expect(r.match_reason).toMatch(/^Role:/);
      expect(r.skills).toEqual(expect.arrayContaining(['Java']));
    }
  });

  it('records the run in import_runs with per-provider detail', async () => {
    const s = await svc([provider('a', 'TestSync-A', [raw(1)])]).run({ trigger: 'test' });
    const run = (await query('SELECT * FROM import_runs WHERE id = $1', [s.runId])).rows[0];
    expect(run).toMatchObject({ data_type: 'jobs_sync', status: 'SUCCESS', received_count: 1, inserted_count: 1 });
    expect(run.completed_at).not.toBeNull();
    expect(run.metadata.providers[0]).toMatchObject({ provider: 'a', status: 'SUCCESS' });
  });

  it('one provider fails -> PARTIAL_SUCCESS; the others still ingest', async () => {
    const s = await svc([
      provider('bad', 'TestSync-Bad', new Error('Greenhouse is down')),
      provider('ok', 'TestSync-Ok', [raw(1)]),
    ]).run({ trigger: 'test' });
    expect(s.status).toBe('PARTIAL_SUCCESS');
    expect(s).toMatchObject({ providersSucceeded: 1, providersFailed: 1, jobsInserted: 1 });
    expect(s.providers.find((p) => p.provider === 'bad')).toMatchObject({ status: 'FAILED', errors: ['Greenhouse is down'] });
    expect(await count()).toBe(1);
  });

  it('multiple providers fail -> still PARTIAL_SUCCESS if any succeed; all fail -> FAILED without throwing', async () => {
    const partial = await svc([
      provider('x', 'TestSync-X', new Error('boom')),
      provider('y', 'TestSync-Y', new Error('boom')),
      provider('z', 'TestSync-Z', [raw(1)]),
    ]).run({ trigger: 'test' });
    expect(partial).toMatchObject({ status: 'PARTIAL_SUCCESS', providersFailed: 2 });

    const none = await svc([provider('x', 'TestSync-X', new Error('boom')), provider('y', 'TestSync-Y', new Error('boom'))]).run({ trigger: 'test' });
    expect(none).toMatchObject({ status: 'FAILED', providersSucceeded: 0, providersFailed: 2 });
    const run = (await query('SELECT status, error_message FROM import_runs WHERE id = $1', [none.runId])).rows[0];
    expect(run.status).toBe('FAILED');
    expect(run.error_message).toMatch(/boom/);
  });

  it('a provider that hangs is cut off by the provider timeout', async () => {
    const slowCfg = { ...cfg, providerTimeoutMs: 1000 };
    const hang: JobProvider = { id: 'hang', source: 'TestSync-Hang', fetchJobs: () => new Promise(() => undefined) };
    const s = await new JobSyncService({ cfg: slowCfg, providers: [hang, provider('ok', 'TestSync-Ok', [raw(1)])] }).run({ trigger: 'test' });
    expect(s.status).toBe('PARTIAL_SUCCESS');
    expect(s.providers.find((p) => p.provider === 'hang')?.errors[0]).toMatch(/timed out/);
  });

  it('zero enabled providers is a FAILED run, not a silent success', async () => {
    expect((await svc([]).run({ trigger: 'test' })).status).toBe('FAILED');
  });

  it('dry run fetches and filters but writes nothing (no rows, no run, no lock)', async () => {
    const s = await svc([provider('a', 'TestSync-A', [raw(1), raw(2)])]).run({ trigger: 'test', dryRun: true });
    expect(s).toMatchObject({ dryRun: true, jobsAccepted: 2, jobsInserted: 0, runId: null });
    expect(await count()).toBe(0);
    expect(Number((await query("SELECT COUNT(*) AS n FROM import_runs WHERE data_type='jobs_sync'")).rows[0].n)).toBe(0);
  });
});

describe('sync: end-to-end retry via the real HTTP client', () => {
  const leverJson = [{ id: 'l1', text: 'Backend Engineer', hostedUrl: 'https://jobs.lever.co/x/l1', categories: { location: 'Bengaluru' }, descriptionPlain: 'Java Spring Boot', createdAt: Date.now() - 86_400_000 }];
  const withFetch = (impl: () => Response) => {
    const calls = { n: 0 };
    const http = new HttpClient(cfg.http, ALLOWED_HOSTS, {
      fetchImpl: (async () => { calls.n++; return impl(); }) as unknown as typeof fetch,
      sleep: async () => undefined,
    });
    return { calls, service: new JobSyncService({ cfg: { ...cfg, leverOrgs: ['x'] }, providers: [leverProvider], http }) };
  };

  it('retries a transient 503 then ingests', async () => {
    let attempt = 0;
    const { calls, service } = withFetch(() => (++attempt < 3 ? new Response('', { status: 503 }) : new Response(JSON.stringify(leverJson))));
    const s = await service.run({ trigger: 'test' });
    expect(calls.n).toBe(3);
    expect(s).toMatchObject({ status: 'SUCCESS', jobsInserted: 1 });
  });

  it('does not retry a 403; the provider is reported FAILED', async () => {
    const { calls, service } = withFetch(() => new Response('', { status: 403 }));
    const s = await service.run({ trigger: 'test' });
    expect(calls.n).toBe(1);
    expect(s.status).toBe('FAILED');
  });
});

describe('deduplication', () => {
  it('is idempotent: a second identical sync inserts nothing and refreshes last_seen_at', async () => {
    const p = provider('a', 'TestSync-A', [raw(1), raw(2)]);
    await svc([p]).run({ trigger: 'test' });
    await query("UPDATE jobs SET last_seen_at = NOW() - interval '5 hours' WHERE source = 'TestSync-A'");
    const second = await svc([p]).run({ trigger: 'test' });
    expect(second).toMatchObject({ jobsInserted: 0, jobsUpdated: 0, jobsDeduplicated: 2 });
    expect(await count()).toBe(2);
    const recent = (await query("SELECT COUNT(*) AS n FROM jobs WHERE source='TestSync-A' AND last_seen_at > NOW() - interval '1 minute'")).rows[0].n;
    expect(Number(recent)).toBe(2);
  });

  it('level 1: same source + external_id updates the existing row (no duplicate)', async () => {
    await svc([provider('a', 'TestSync-A', [raw(1)])]).run({ trigger: 'test' });
    const changed = raw(1, { title: 'Backend Engineer (Java)', description: 'Java Spring Boot PostgreSQL Docker, completely rewritten posting text.' });
    const s = await svc([provider('a', 'TestSync-A', [changed])]).run({ trigger: 'test' });
    expect(s).toMatchObject({ jobsInserted: 0, jobsUpdated: 1 });
    const rows = (await query("SELECT title, description FROM jobs WHERE source='TestSync-A'")).rows;
    expect(rows).toHaveLength(1);
    expect(rows[0].title).toBe('Backend Engineer (Java)');
  });

  it('level 2: same canonical URL (tracking params differ) is not re-inserted', async () => {
    await svc([provider('a', 'TestSync-A', [raw(1)])]).run({ trigger: 'test' });
    const s = await svc([provider('a', 'TestSync-A', [raw(1, { externalId: 'new-id', url: 'https://www.jobs.example.com/1/?utm_source=x#frag' })])]).run({ trigger: 'test' });
    expect(s.jobsInserted).toBe(0);
    expect(await count()).toBe(1);
  });

  it('level 3: same company+title+location from a different source/URL is a duplicate', async () => {
    await svc([provider('a', 'TestSync-A', [raw(1)])]).run({ trigger: 'test' });
    const s = await svc([provider('b', 'TestSync-B', [raw(1, { externalId: 'zzz', url: 'https://other.example.org/posting?id=9', company: 'ACME Inc.', location: 'Bangalore, India' })])]).run({ trigger: 'test' });
    expect(s).toMatchObject({ jobsInserted: 0, jobsDeduplicated: 1 });
    expect(await count()).toBe(1);
  });

  it('level 4: same company + identical long description, re-titled, is a duplicate', async () => {
    const description = 'We are hiring a backend engineer to design Java Spring Boot services. '.repeat(8);
    await svc([provider('a', 'TestSync-A', [raw(1, { description })])]).run({ trigger: 'test' });
    const s = await svc([provider('b', 'TestSync-B', [raw(1, { externalId: 'q', url: 'https://x.example.net/q', title: 'Software Engineer, Platform Backend', description })])]).run({ trigger: 'test' });
    expect(s.jobsInserted).toBe(0);
    expect(await count()).toBe(1);
  });

  it('level 4 is conservative: shared JD text with a different title AND location stays a separate job', async () => {
    const description = 'We are hiring a backend engineer to design Java Spring Boot services. '.repeat(8);
    await svc([provider('a', 'TestSync-A', [raw(1, { description })])]).run({ trigger: 'test' });
    const s = await svc([provider('b', 'TestSync-B', [raw(1, { externalId: 'q', url: 'https://x.example.net/q', title: 'Software Engineer, Platform Backend', location: 'Pune, India', description })])]).run({ trigger: 'test' });
    expect(s.jobsInserted).toBe(1);
    expect(await count()).toBe(2);
  });

  it('cross-posts inside one run (e.g. RemoteOK + WWR) are collapsed', async () => {
    const s = await svc([
      provider('a', 'TestSync-A', [raw(1, { location: 'Remote - Anywhere' })]),
      provider('b', 'TestSync-B', [raw(1, { externalId: 'wwr-1', url: 'https://weworkremotely.com/jobs/1', location: 'Remote - Anywhere' })]),
    ]).run({ trigger: 'test' });
    expect(s).toMatchObject({ jobsInserted: 1, jobsDeduplicated: 1 });
    expect(await count()).toBe(1);
  });

  it('concurrent inserts of the same job create exactly one row', async () => {
    const n = normalizeJob({ ...raw(1), source: 'TestSync-A' });
    if (!n.ok) throw new Error(n.reason);
    const m = matcher.evaluate(n.job);
    const outcomes = await Promise.all(Array.from({ length: 10 }, () => repo.upsert(n.job, m)));
    expect(outcomes.filter((o) => o === 'inserted')).toHaveLength(1);
    expect(await count()).toBe(1);
  });

  it('preserves user data (is_saved, notes) when a job is refreshed', async () => {
    await svc([provider('a', 'TestSync-A', [raw(1)])]).run({ trigger: 'test' });
    await query("UPDATE jobs SET is_saved = TRUE, notes = 'apply friday' WHERE source = 'TestSync-A'");
    await svc([provider('a', 'TestSync-A', [raw(1, { description: 'Java Spring Boot, edited description with new words.' })])]).run({ trigger: 'test' });
    const r = (await query("SELECT is_saved, notes FROM jobs WHERE source = 'TestSync-A'")).rows[0];
    expect(r).toMatchObject({ is_saved: true, notes: 'apply friday' });
  });
});

describe('filtering during sync', () => {
  it('rejects irrelevant jobs, counts reasons, stores only relevant ones', async () => {
    const s = await svc([
      provider('a', 'TestSync-A', [
        raw(1),
        raw(2, { title: 'Senior Staff Software Engineer' }),
        raw(3, { title: 'Sales Development Representative' }),
        raw(4, { description: '8+ years of experience required' }),
        raw(5, { location: 'Remote - USA Only' }),
        raw(6, { url: 'javascript:alert(1)' }),
        raw(7, { title: 'Software Engineering Intern' }),
      ]),
    ]).run({ trigger: 'test' });
    expect(s).toMatchObject({ jobsDiscovered: 7, jobsInserted: 1, jobsRejected: 6 });
    expect(s.rejectionReasons).toMatchObject({ seniority: 1, experience: 1, location: 1, invalid_url: 1 });
    expect(await count()).toBe(1);
  });
});

describe('freshness', () => {
  const age = (interval: string) =>
    query(`UPDATE jobs SET last_seen_at = NOW() - interval '${interval}' WHERE source = 'TestSync-A' AND external_id = 'ext-1'`);
  const status = async () =>
    (await query("SELECT status FROM jobs WHERE source = 'TestSync-A' AND external_id = 'ext-1'")).rows[0].status;

  it('OPEN -> STALE -> CLOSED when unseen, and back to OPEN when it reappears; never deleted', async () => {
    await svc([provider('a', 'TestSync-A', [raw(1)])]).run({ trigger: 'test' });
    const empty = provider('a', 'TestSync-A', [raw(2)]); // job 1 disappears from the provider

    await age('3 days');
    const stale = await svc([empty]).run({ trigger: 'test' });
    expect(stale.jobsMarkedStale).toBeGreaterThanOrEqual(1);
    expect(await status()).toBe('STALE');

    await query("UPDATE jobs SET last_seen_at = NOW() - interval '20 days' WHERE source = 'TestSync-A' AND external_id = 'ext-1'");
    await svc([empty]).run({ trigger: 'test' });
    expect((await query("SELECT status FROM jobs WHERE source='TestSync-A' AND external_id='ext-1'")).rows[0].status).toBe('CLOSED');

    await svc([provider('a', 'TestSync-A', [raw(1)])]).run({ trigger: 'test' });
    expect((await query("SELECT status FROM jobs WHERE source='TestSync-A' AND external_id='ext-1'")).rows[0].status).toBe('OPEN');
    expect(await count()).toBe(2);
  });

  it('a failed provider never causes its jobs to be marked stale', async () => {
    await svc([provider('a', 'TestSync-A', [raw(1)])]).run({ trigger: 'test' });
    await age('30 days');
    await svc([provider('a', 'TestSync-A', new Error('outage')), provider('ok', 'TestSync-Ok', [raw(9)])]).run({ trigger: 'test' });
    expect(await status()).toBe('OPEN');
  });

  it('jobs from sources that are not synced (manual entries) are never touched', async () => {
    await query(`INSERT INTO jobs (id, title, company, source, last_seen_at, status) VALUES ($1, 'Manual', 'Me', 'TestSync-Manual', NOW() - interval '90 days', 'OPEN')`, [randomUUID()]);
    await svc([provider('a', 'TestSync-A', [raw(1)])]).run({ trigger: 'test' });
    expect((await query("SELECT status FROM jobs WHERE source='TestSync-Manual'")).rows[0].status).toBe('OPEN');
  });

  it('threshold is configurable', async () => {
    await svc([provider('a', 'TestSync-A', [raw(1)])]).run({ trigger: 'test' });
    await age('3 hours');
    const strict = new JobSyncService({ cfg: { ...cfg, staleAfterHours: 2 }, providers: [provider('a', 'TestSync-A', [raw(2)])] });
    await strict.run({ trigger: 'test' });
    expect((await query("SELECT status FROM jobs WHERE source='TestSync-A' AND external_id='ext-1'")).rows[0].status).toBe('STALE');
  });
});

describe('sync lock', () => {
  it('a simultaneous second sync exits safely without duplicating work', async () => {
    const slow = provider('a', 'TestSync-A', [raw(1), raw(2)], 400);
    const [a, b] = await Promise.all([svc([slow]).run({ trigger: 'test' }), svc([slow]).run({ trigger: 'test' })]);
    const statuses = [a.status, b.status].sort();
    expect(statuses).toEqual(['SKIPPED_LOCKED', 'SUCCESS']);
    expect(await count()).toBe(2);
    // The skipped run must not leave a run row behind.
    expect(Number((await query("SELECT COUNT(*) AS n FROM import_runs WHERE data_type='jobs_sync'")).rows[0].n)).toBe(1);
  });

  it('releases the lock after a run, even a failed one', async () => {
    await svc([provider('x', 'TestSync-X', new Error('boom'))]).run({ trigger: 'test' });
    expect(await repo.acquireLock('someone-else', 30)).toBe(true);
  });

  it('only one of many concurrent acquirers wins; an expired lease can be taken over', async () => {
    const wins = await Promise.all(Array.from({ length: 10 }, (_, i) => repo.acquireLock(`o${i}`, 60)));
    expect(wins.filter(Boolean)).toHaveLength(1);
    await query("UPDATE job_sync_locks SET locked_until = NOW() - interval '1 second' WHERE name = $1", [LOCK_NAME]);
    expect(await repo.acquireLock('successor', 60)).toBe(true);
  });

  it('crashed predecessors are cleaned up: stale IN_PROGRESS runs become FAILED', async () => {
    const id = await repo.createRun('test'); // never finished
    await svc([provider('a', 'TestSync-A', [raw(1)])]).run({ trigger: 'test' });
    expect((await query('SELECT status FROM import_runs WHERE id = $1', [id])).rows[0].status).toBe('FAILED');
  });
});

describe('security: secrets never leak', () => {
  it('redacts secrets, bearer tokens and DB credentials from log text', () => {
    const secret = config.jobSyncSecret;
    expect(secret.length).toBeGreaterThan(20);
    const out = redact(`failed with ${secret} and Authorization: Bearer abcdefghijklmnop and postgresql://user:hunter2@db.host/x`);
    expect(out).not.toContain(secret);
    expect(out).not.toContain('abcdefghijklmnop');
    expect(out).not.toContain('hunter2');
  });

  it('a provider error containing the secret reaches neither logs, the response summary nor the database', async () => {
    process.env.LOG_IN_TESTS = '1';
    const out: string[] = [];
    const spies = (['log', 'warn', 'error'] as const).map((m) => jest.spyOn(console, m).mockImplementation((...a: unknown[]) => void out.push(a.join(' '))));
    try {
      const evil = provider('evil', 'TestSync-Evil', new Error(`upstream said Authorization: Bearer ${config.jobSyncSecret} / ${config.jobSyncSecret}`));
      const s = await svc([evil, provider('ok', 'TestSync-Ok', [raw(1)])]).run({ trigger: 'test' });
      const dbRow = JSON.stringify((await query('SELECT * FROM import_runs WHERE id = $1', [s.runId])).rows[0]);
      expect(out.length).toBeGreaterThan(0); // logging really happened
      for (const text of [...out, JSON.stringify(s), dbRow]) expect(text).not.toContain(config.jobSyncSecret);
    } finally {
      spies.forEach((sp) => sp.mockRestore());
      delete process.env.LOG_IN_TESTS;
    }
  });
});

describe('database: migration, indexes and constraints', () => {
  it('schema checks pass (tables, columns, indexes, migration recorded)', async () => {
    for (const c of await checkSchema()) expect({ [c.name]: c.ok, detail: c.detail }).toEqual({ [c.name]: true, detail: expect.any(String) });
  });

  it('migration 005 is idempotent (safe to re-run)', async () => {
    const sql = fs.readFileSync(path.resolve(__dirname, '../migrations/005_job_sync.sql'), 'utf8');
    await expect(query(sql)).resolves.toBeDefined();
    await expect(query(sql)).resolves.toBeDefined();
  });

  const ins = (id: string, o: Record<string, string | null>) =>
    query(
      `INSERT INTO jobs (id, title, company, source, external_id, canonical_url, dedupe_key, url)
       VALUES ($1, 'T', 'C', $2, $3, $4, $5, $6)`,
      [id, o.source ?? 'TestSync-DB', o.ext ?? null, o.canon ?? null, o.key ?? null, o.url ?? null]
    );

  it('unique constraints reject duplicates at the database level', async () => {
    await ins(randomUUID(), { ext: 'e1', canon: 'https://c.com/1', key: 'k1' });
    await expect(ins(randomUUID(), { ext: 'e1' })).rejects.toMatchObject({ code: '23505' }); // source+external_id
    await expect(ins(randomUUID(), { ext: 'e2', canon: 'https://c.com/1' })).rejects.toMatchObject({ code: '23505' }); // canonical_url
    await expect(ins(randomUUID(), { ext: 'e3', canon: 'https://c.com/3', key: 'k1' })).rejects.toMatchObject({ code: '23505' }); // dedupe_key
    await expect(ins(randomUUID(), { ext: 'e4', canon: null, key: null })).resolves.toBeDefined(); // NULL keys never collide
    await expect(ins(randomUUID(), { ext: 'e5', canon: null, key: null })).resolves.toBeDefined();
  });

  it('status is constrained to OPEN/CLOSED/STALE/UNKNOWN and defaults to OPEN', async () => {
    const id = randomUUID();
    await ins(id, { ext: 'st1' });
    expect((await query('SELECT status FROM jobs WHERE id = $1', [id])).rows[0].status).toBe('OPEN');
    await expect(query("UPDATE jobs SET status = 'BOGUS' WHERE id = $1", [id])).rejects.toMatchObject({ code: '23514' });
  });
});
