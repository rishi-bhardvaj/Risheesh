import request from 'supertest';
import { createApp } from '../src/app';
import { config } from '../src/config';
import { pool, query } from '../src/db';
import { resetJobSyncAuthLimiter } from '../src/middleware/jobSyncAuth';
import { setJobSyncServiceForTests } from '../src/modules/job-sync/job-sync.controller';
import { loadJobSyncConfig } from '../src/modules/job-sync/job-sync.config';
import { LOCK_NAME } from '../src/modules/job-sync/job-sync.repository';
import { JobSyncService } from '../src/modules/job-sync/job-sync.service';
import type { JobProvider, RawJob } from '../src/modules/job-sync/types';

const app = createApp();
const SECRET = config.jobSyncSecret;
const auth = { Authorization: `Bearer ${SECRET}` };
const cfg = loadJobSyncConfig({ JOB_SYNC_BOARD_DELAY_MS: '0' } as unknown as NodeJS.ProcessEnv);

const raw = (n: number): RawJob => ({
  source: 'x',
  externalId: `api-${n}`,
  url: `https://jobs.example.com/api/${n}`,
  title: `Backend Engineer ${String.fromCharCode(64 + n)}`,
  company: 'ApiCo',
  location: 'Bengaluru, India',
  description: 'Java Spring Boot PostgreSQL. 0-2 years experience.',
});
const okProvider = (jobs: RawJob[], delay = 0): JobProvider => ({
  id: 'p',
  source: 'TestSyncApi',
  fetchJobs: async () => {
    if (delay) await new Promise((r) => setTimeout(r, delay));
    return { jobs, boardsAttempted: 1, boardsFailed: 0, errors: [] };
  },
});
const failProvider: JobProvider = { id: 'f', source: 'TestSyncApiFail', fetchJobs: async () => { throw new Error('down'); } };

async function cleanup() {
  await query("DELETE FROM jobs WHERE source LIKE 'TestSync%'");
  await query("DELETE FROM import_runs WHERE data_type = 'jobs_sync'");
  await query('DELETE FROM job_sync_locks WHERE name = $1', [LOCK_NAME]);
}

beforeEach(async () => {
  resetJobSyncAuthLimiter();
  await cleanup();
});
afterAll(async () => {
  setJobSyncServiceForTests(null);
  config.jobSyncSecret = SECRET;
  await cleanup();
  await pool.end();
});

describe('POST /api/v1/internal/jobs/sync: security', () => {
  it('401 without Authorization header', async () => {
    const res = await request(app).post('/api/v1/internal/jobs/sync');
    expect(res.status).toBe(401);
    expect(res.body).toMatchObject({ success: false, error: { code: 'UNAUTHORIZED' } });
  });

  it('401 with a wrong secret, and the response never echoes either secret', async () => {
    const res = await request(app).post('/api/v1/internal/jobs/sync').set('Authorization', 'Bearer definitely-the-wrong-secret-value');
    expect(res.status).toBe(401);
    expect(JSON.stringify(res.body)).not.toContain(SECRET);
    expect(JSON.stringify(res.body)).not.toContain('definitely-the-wrong');
  });

  it('401 for a malformed scheme or the import API key (different credential)', async () => {
    expect((await request(app).post('/api/v1/internal/jobs/sync').set('Authorization', `Basic ${SECRET}`)).status).toBe(401);
    expect((await request(app).post('/api/v1/internal/jobs/sync').set('Authorization', `Bearer ${config.importApiKey}`)).status).toBe(401);
  });

  it('503 (fail closed) when JOB_SYNC_SECRET is unset or too short, even with a matching header', async () => {
    for (const weak of ['', 'short']) {
      config.jobSyncSecret = weak;
      const res = await request(app).post('/api/v1/internal/jobs/sync').set('Authorization', `Bearer ${weak}`);
      expect(res.status).toBe(503);
      expect(res.body.error.code).toBe('SYNC_NOT_CONFIGURED');
    }
    config.jobSyncSecret = SECRET;
  });

  it('429 after repeated failed attempts (brute-force brake), valid secret still gated afterwards', async () => {
    for (let i = 0; i < 20; i++) await request(app).post('/api/v1/internal/jobs/sync').set('Authorization', 'Bearer nope-nope-nope-nope-nope-nope');
    const res = await request(app).post('/api/v1/internal/jobs/sync').set(auth);
    expect(res.status).toBe(429);
  });

  it('status endpoint is protected too', async () => {
    expect((await request(app).get('/api/v1/internal/jobs/sync/status')).status).toBe(401);
    expect((await request(app).get('/api/v1/internal/jobs/sync/status').set(auth)).status).toBe(200);
  });

  it('rejects unknown body fields / providers (input validation)', async () => {
    setJobSyncServiceForTests(new JobSyncService({ cfg, providers: [okProvider([raw(1)])] }));
    expect((await request(app).post('/api/v1/internal/jobs/sync').set(auth).send({ providers: ['../../etc'] })).status).toBe(400);
    expect((await request(app).post('/api/v1/internal/jobs/sync').set(auth).send({ url: 'http://169.254.169.254' })).status).toBe(400);
  });
});

describe('POST /api/v1/internal/jobs/sync: behaviour', () => {
  it('200 SUCCESS with a valid secret; jobs become visible via GET /api/v1/jobs', async () => {
    setJobSyncServiceForTests(new JobSyncService({ cfg, providers: [okProvider([raw(1), raw(2)])] }));
    const res = await request(app).post('/api/v1/internal/jobs/sync').set(auth).send({});
    expect(res.status).toBe(200);
    expect(res.body.data).toMatchObject({ status: 'SUCCESS', jobsInserted: 2 });
    expect(JSON.stringify(res.body)).not.toContain(SECRET);

    const list = await request(app).get('/api/v1/jobs?source=TestSyncApi');
    expect(list.body.pagination.total).toBe(2);
  });

  it('is idempotent across repeated hourly calls', async () => {
    setJobSyncServiceForTests(new JobSyncService({ cfg, providers: [okProvider([raw(1), raw(2)])] }));
    await request(app).post('/api/v1/internal/jobs/sync').set(auth);
    const second = await request(app).post('/api/v1/internal/jobs/sync').set(auth);
    expect(second.body.data).toMatchObject({ jobsInserted: 0, jobsDeduplicated: 2 });
    expect((await request(app).get('/api/v1/jobs?source=TestSyncApi')).body.pagination.total).toBe(2);
  });

  it('200 PARTIAL_SUCCESS when one provider fails; 502 when all fail', async () => {
    setJobSyncServiceForTests(new JobSyncService({ cfg, providers: [failProvider, okProvider([raw(1)])] }));
    const partial = await request(app).post('/api/v1/internal/jobs/sync').set(auth);
    expect(partial.status).toBe(200);
    expect(partial.body.data.status).toBe('PARTIAL_SUCCESS');

    setJobSyncServiceForTests(new JobSyncService({ cfg, providers: [failProvider] }));
    const failed = await request(app).post('/api/v1/internal/jobs/sync').set(auth);
    expect(failed.status).toBe(502);
    expect(failed.body.data.status).toBe('FAILED');
  });

  it('409 when another sync is already running', async () => {
    setJobSyncServiceForTests(new JobSyncService({ cfg, providers: [okProvider([raw(1)], 500)] }));
    const [a, b] = await Promise.all([
      request(app).post('/api/v1/internal/jobs/sync').set(auth),
      request(app).post('/api/v1/internal/jobs/sync').set(auth),
    ]);
    expect([a.status, b.status].sort()).toEqual([200, 409]);
    const loser = a.status === 409 ? a : b;
    expect(loser.body.error.code).toBe('SYNC_IN_PROGRESS');
  });

  it('dryRun: true writes nothing', async () => {
    setJobSyncServiceForTests(new JobSyncService({ cfg, providers: [okProvider([raw(1)])] }));
    const res = await request(app).post('/api/v1/internal/jobs/sync').set(auth).send({ dryRun: true });
    expect(res.body.data).toMatchObject({ dryRun: true, jobsAccepted: 1, jobsInserted: 0 });
    expect((await request(app).get('/api/v1/jobs?source=TestSyncApi')).body.pagination.total).toBe(0);
  });

  it('wait=false acknowledges with 202 and completes in the background', async () => {
    setJobSyncServiceForTests(new JobSyncService({ cfg, providers: [okProvider([raw(1)])] }));
    const res = await request(app).post('/api/v1/internal/jobs/sync?wait=false').set(auth);
    expect(res.status).toBe(202);
    await new Promise((r) => setTimeout(r, 600));
    expect((await request(app).get('/api/v1/jobs?source=TestSyncApi')).body.pagination.total).toBe(1);
  });

  it('GET status reflects the last run in the documented shape', async () => {
    setJobSyncServiceForTests(new JobSyncService({ cfg, providers: [okProvider([raw(1), raw(2)])] }));
    await request(app).post('/api/v1/internal/jobs/sync').set(auth);
    const res = await request(app).get('/api/v1/internal/jobs/sync/status').set(auth);
    expect(res.body.data).toMatchObject({ status: 'SUCCESS', jobsDiscovered: 2, jobsInserted: 2, jobsUpdated: 0, jobsRejected: 0, healthy: true });
    expect(res.body.data.lastSync).toBeTruthy();
    expect(res.body.data.jobsByStatus.OPEN).toBeGreaterThanOrEqual(2);
    expect(JSON.stringify(res.body)).not.toContain(SECRET);
  });
});

describe('GET /api/v1/jobs: pagination, filtering, sorting', () => {
  const seed = async () => {
    const rows: Array<[string, string, string, number, string | null, string, string]> = [
      // title, company, source, score, posted_date, status, location
      ['Alpha Engineer', 'ZetaCo', 'TestSyncA', 90, '2026-09-01T00:00:00Z', 'OPEN', 'Bengaluru'],
      ['Beta Engineer', 'AlphaCo', 'TestSyncA', 70, '2026-09-20T00:00:00Z', 'OPEN', 'Remote'],
      ['Gamma Engineer', 'MidCo', 'TestSyncB', 70, '2026-09-25T00:00:00Z', 'OPEN', 'Pune'],
      ['Delta Engineer', 'MidCo', 'TestSyncB', 50, null, 'STALE', 'Pune'],
      ['Epsilon Engineer', 'OldCo', 'TestSyncB', 95, '2026-01-01T00:00:00Z', 'CLOSED', 'Pune'],
    ];
    for (const [i, r] of rows.entries()) {
      await query(
        `INSERT INTO jobs (id, title, company, source, match_score, posted_date, status, location, external_id, description)
         VALUES (uuid_generate_v4(), $1, $2, $3, $4, $5, $6, $7, $8, 'searchable-needle')`,
        [r[0], r[1], r[2], r[3], r[4], r[5], r[6], `seed-${i}`]
      );
    }
  };
  const get = (qs: string) => request(app).get(`/api/v1/jobs?${qs.includes('source=') ? '' : 'source=TestSync&'}${qs}`);

  it('default view: OPEN only, sorted by match_score DESC then posted_date DESC', async () => {
    await seed();
    const res = await get('');
    expect(res.status).toBe(200);
    expect(res.body.data.map((j: { title: string }) => j.title)).toEqual(['Alpha Engineer', 'Gamma Engineer', 'Beta Engineer']);
    expect(res.body.pagination).toMatchObject({ page: 1, limit: 25, total: 3, totalPages: 1 });
  });

  it('server-side pagination is stable and exhaustive', async () => {
    await seed();
    const p1 = await get('status=ALL&limit=2&page=1');
    const p2 = await get('status=ALL&limit=2&page=2');
    const p3 = await get('status=ALL&limit=2&page=3');
    expect(p1.body.pagination).toMatchObject({ total: 5, totalPages: 3, limit: 2 });
    const ids = [...p1.body.data, ...p2.body.data, ...p3.body.data].map((j: { id: string }) => j.id);
    expect(ids).toHaveLength(5);
    expect(new Set(ids).size).toBe(5);
  });

  it('filters: status, min_score, source, location, search, posted_after', async () => {
    await seed();
    expect((await get('status=STALE')).body.data.map((j: { title: string }) => j.title)).toEqual(['Delta Engineer']);
    expect((await get('status=CLOSED')).body.pagination.total).toBe(1);
    expect((await get('status=ALL')).body.pagination.total).toBe(5);
    expect((await get('min_score=80&status=ALL')).body.data).toHaveLength(2);
    expect((await get('source=TestSyncB&status=ALL')).body.pagination.total).toBe(3);
    expect((await get('location=pune')).body.pagination.total).toBe(1);
    expect((await get('search=needle')).body.pagination.total).toBe(3);
    expect((await get('posted_after=2026-09-15')).body.data.map((j: { title: string }) => j.title).sort()).toEqual(['Beta Engineer', 'Gamma Engineer']);
  });

  it('explicit sorts still work (newest, company, title)', async () => {
    await seed();
    expect((await get('sort=company')).body.data[0].company).toBe('AlphaCo');
    expect((await get('sort=title')).body.data[0].title).toBe('Alpha Engineer');
  });

  it('rejects invalid query values with 400 and caps limit', async () => {
    expect((await get('status=BOGUS')).status).toBe(400);
    expect((await get('limit=100000')).status).toBe(400);
    expect((await get('min_score=abc')).status).toBe(400);
    expect((await get('sort=drop_table')).status).toBe(400);
  });

  it('is safe against SQL injection in filters', async () => {
    await seed();
    const res = await get("search=" + encodeURIComponent("'; DROP TABLE jobs; --"));
    expect(res.status).toBe(200);
    expect(res.body.pagination.total).toBe(0);
    expect(Number((await query('SELECT COUNT(*) AS n FROM jobs')).rows[0].n)).toBeGreaterThan(0);
  });

  it('never returns raw_data and exposes freshness fields', async () => {
    await seed();
    const job = (await get('')).body.data[0];
    expect(job).not.toHaveProperty('raw_data');
    expect(job).toHaveProperty('status');
    expect(job).toHaveProperty('match_score');
    expect(job).toHaveProperty('last_seen_at');
  });
});
