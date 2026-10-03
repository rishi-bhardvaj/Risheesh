/**
 * End-to-end self check. Exits non-zero if anything required is broken.
 *
 *   npm run jobs:verify            # offline: DB, schema, lock, pipeline (stub provider), HTTP API
 *   npm run jobs:verify -- --live  # additionally dry-runs the real providers over the network
 */
import { randomUUID } from 'crypto';
import http from 'http';
import { AddressInfo } from 'net';
import { createApp } from '../src/app';
import { config } from '../src/config';
import { checkDatabaseConnection, pool } from '../src/db';
import { MIN_SECRET_LENGTH } from '../src/middleware/jobSyncAuth';
import { checkSchema } from '../src/modules/job-sync/job-sync.health';
import { loadJobSyncConfig } from '../src/modules/job-sync/job-sync.config';
import { JobMatchingService } from '../src/modules/job-sync/job-matching.service';
import { normalizeJob } from '../src/modules/job-sync/job-normalization.service';
import { JobSyncService } from '../src/modules/job-sync/job-sync.service';
import { jobSyncRepository } from '../src/modules/job-sync/job-sync.repository';
import { ALL_PROVIDERS } from '../src/modules/job-sync/providers';
import type { JobProvider } from '../src/modules/job-sync/types';

let failures = 0;
const ok = (label: string, detail = '') => console.log(`✓ ${label}${detail ? ` - ${detail}` : ''}`);
const warn = (label: string, detail = '') => console.log(`⚠ ${label}${detail ? ` - ${detail}` : ''}`);
const bad = (label: string, detail = '') => {
  failures++;
  console.log(`✗ ${label}${detail ? ` - ${detail}` : ''}`);
};
const check = (cond: boolean, label: string, detail = '') => (cond ? ok(label, detail) : bad(label, detail));

// JobDto (Flutter) reads these keys from GET /api/v1/jobs items.
const FLUTTER_JOB_KEYS = ['id', 'title', 'company', 'location', 'salary', 'employment_type', 'url', 'source', 'description', 'skills', 'posted_date', 'discovered_at', 'match_score', 'match_reason', 'is_saved'];

async function main(): Promise<void> {
  const live = process.argv.includes('--live');

  // environment
  check(config.jobSyncSecret.length >= MIN_SECRET_LENGTH, 'environment: JOB_SYNC_SECRET', config.jobSyncSecret ? 'configured' : 'missing - run npm run jobs:setup');
  check(Boolean(process.env.DATABASE_URL), 'environment: DATABASE_URL');

  // database + schema
  const dbOk = await checkDatabaseConnection();
  check(dbOk, 'database connection');
  if (!dbOk) return;
  for (const c of await checkSchema()) check(c.ok, `schema: ${c.name}`, c.detail);

  // providers
  const cfg = loadJobSyncConfig();
  const unknown = cfg.enabledProviders.filter((id) => !ALL_PROVIDERS.some((p) => p.id === id));
  check(unknown.length === 0 && cfg.enabledProviders.length > 0, 'providers initialise', unknown.length ? `unknown: ${unknown.join(', ')}` : cfg.enabledProviders.join(', '));

  // matching
  const matcher = new JobMatchingService(cfg);
  const good = normalizeJob({ source: 'Verify', externalId: '1', url: 'https://example.com/j/1', title: 'Backend Engineer (Java, Spring Boot)', company: 'Acme', location: 'Bengaluru, India', description: 'Build REST APIs with Java, Spring Boot, PostgreSQL and Docker. 0-2 years experience.' });
  const senior = normalizeJob({ source: 'Verify', externalId: '2', url: 'https://example.com/j/2', title: 'Senior Staff Engineer', company: 'Acme', location: 'Bengaluru', description: '10+ years of experience' });
  const m1 = good.ok ? matcher.evaluate(good.job) : null;
  const m2 = senior.ok ? matcher.evaluate(senior.job) : null;
  check(Boolean(m1?.accepted) && m2?.accepted === false, 'matching service', `relevant=${m1?.score} senior=${m2?.rejection}`);

  // sync lock
  const a = randomUUID();
  const b = randomUUID();
  if (await jobSyncRepository.acquireLock(a, 60)) {
    check(!(await jobSyncRepository.acquireLock(b, 60)), 'sync lock: second holder refused');
    await jobSyncRepository.releaseLock(a);
    const again = await jobSyncRepository.acquireLock(b, 60);
    check(again, 'sync lock: re-acquirable after release');
    await jobSyncRepository.releaseLock(b);
  } else {
    warn('sync lock', 'currently held by a running sync; skipped');
  }

  // sync service (offline stub, dry run: writes nothing)
  const stub: JobProvider = {
    id: 'stub',
    source: 'Verify',
    fetchJobs: async () => ({
      jobs: [{ source: 'Verify', externalId: '1', url: 'https://example.com/j/1', title: 'Backend Engineer', company: 'Acme', location: 'Bengaluru', description: 'Java Spring Boot' }],
      boardsAttempted: 1,
      boardsFailed: 0,
      errors: [],
    }),
  };
  const dry = await new JobSyncService({ providers: [stub] }).run({ trigger: 'verify', dryRun: true });
  check(dry.status === 'SUCCESS' && dry.jobsAccepted === 1, 'sync service (stub, dry run)', `status=${dry.status}`);

  if (live) {
    const liveRun = await new JobSyncService().run({ trigger: 'verify', dryRun: true });
    check(liveRun.providersSucceeded > 0, 'live providers (dry run)', `${liveRun.providersSucceeded}/${liveRun.providersAttempted} ok, ${liveRun.jobsAccepted} relevant of ${liveRun.jobsDiscovered}`);
    for (const p of liveRun.providers.filter((x) => x.status !== 'SUCCESS')) warn(`provider ${p.provider}`, `${p.status}: ${p.errors[0] ?? ''}`);
  }

  // HTTP API
  const server = http.createServer(createApp());
  await new Promise<void>((r) => server.listen(0, '127.0.0.1', r));
  const base = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
  try {
    check((await fetch(`${base}/health`)).status === 200, 'api: GET /health');

    const unauth = await fetch(`${base}/api/v1/internal/jobs/sync`, { method: 'POST' });
    check(unauth.status === 401 || unauth.status === 503, 'api: sync endpoint rejects unauthenticated', `HTTP ${unauth.status}`);

    if (config.jobSyncSecret.length >= MIN_SECRET_LENGTH) {
      const st = await fetch(`${base}/api/v1/internal/jobs/sync/status`, { headers: { Authorization: `Bearer ${config.jobSyncSecret}` } });
      check(st.status === 200, 'api: sync status with secret', `HTTP ${st.status}`);
    }

    const jobs = await fetch(`${base}/api/v1/jobs?page=1&limit=5`);
    const body = (await jobs.json()) as { success?: boolean; data?: Array<Record<string, unknown>>; pagination?: Record<string, unknown> };
    check(jobs.status === 200 && body.success === true && Array.isArray(body.data) && Boolean(body.pagination?.totalPages !== undefined), 'api: GET /api/v1/jobs envelope + pagination');
    if (body.data && body.data.length > 0) {
      const missing = FLUTTER_JOB_KEYS.filter((k) => !(k in body.data![0]));
      check(missing.length === 0, 'flutter/backend compatibility (JobDto keys)', missing.length ? `missing: ${missing.join(', ')}` : '');
      check(!('raw_data' in body.data[0]), 'api: raw_data not exposed');
    } else {
      warn('flutter/backend compatibility', 'no jobs in DB yet; run npm run jobs:sync, then re-verify');
    }
  } finally {
    await new Promise((r) => server.close(r));
  }
}

main()
  .catch((err) => bad('verify crashed', err instanceof Error ? err.message : String(err)))
  .finally(async () => {
    await pool.end().catch(() => undefined);
    console.log(failures === 0 ? '\nAll checks passed.' : `\n${failures} check(s) failed.`);
    process.exit(failures === 0 ? 0 : 1);
  });
