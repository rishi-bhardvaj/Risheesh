import request from 'supertest';
import { createApp } from '../src/app';
import { config } from '../src/config';
import { pool, query } from '../src/db';
import { resetAssistantAuthLimiter } from '../src/middleware/assistantAuth';
import { v4 as uuidv4 } from 'uuid';

const app = createApp();
const TEST_KEY = 'test_assistant_api_key_secure_12345';
const authHeader = { Authorization: `Bearer ${TEST_KEY}` };

const testJobId = uuidv4();
const testLeadId = uuidv4();
const testAppId = uuidv4();

async function seedTestData() {
  // 1. Insert test job
  await query(
    `INSERT INTO jobs (
      id, external_id, title, company, location, salary, employment_type,
      experience_requirement, url, source, description, skills, posted_date,
      discovered_at, match_score, match_reason, is_saved, notes, status,
      raw_data
    ) VALUES (
      $1, 'ext-test-1', 'Backend Engineer Java', 'TestCorp', 'Bengaluru, India',
      '20-25 LPA', 'Full-time', '0-2 years', 'https://example.com/job/1',
      'TestAssistant', 'Java Spring Boot PostgreSQL', '["Java","Spring Boot"]'::jsonb,
      NOW() - INTERVAL '2 hours', NOW() - INTERVAL '2 hours', 92, 'Strong Java match',
      true, 'Interview scheduled', 'OPEN', '{"internal_token":"secret_123"}'::jsonb
    )`,
    [testJobId]
  );

  // 2. Insert test freelance lead
  await query(
    `INSERT INTO freelance_leads (
      id, external_id, title, client_name, platform, description, skills,
      budget, currency, url, status, proposal, deadline, lead_date,
      match_score, match_reason, raw_data, created_at, updated_at
    ) VALUES (
      $1, 'lead-test-1', 'Spring Boot API Migration', 'Acme Client', 'Upwork',
      'Migrate REST API to Spring Boot 3', '["Java","Spring"]'::jsonb,
      1500, 'USD', 'https://upwork.com/jobs/1', 'NEW_LEAD',
      'Draft proposal ready', NOW() + INTERVAL '7 days', NOW() - INTERVAL '1 hour',
      88, 'Strong backend match', '{"client_secret_contact":"confidential"}'::jsonb,
      NOW() - INTERVAL '1 hour', NOW() - INTERVAL '1 hour'
    )`,
    [testLeadId]
  );

  // 3. Insert test job application
  await query(
    `INSERT INTO job_applications (
      id, job_id, company, role, salary, location, url, status,
      applied_at, follow_up_date, recruiter_name, recruiter_contact,
      resume_id, notes, created_at, updated_at
    ) VALUES (
      $1, $2, 'TestCorp', 'Backend Engineer', '20 LPA', 'Bengaluru',
      'https://example.com/job/1', 'interviewing', NOW() - INTERVAL '3 hours',
      NOW() - INTERVAL '1 hour', 'Alice Recruiter', 'alice@testcorp.com',
      'res-priv-99', 'First round passed', NOW() - INTERVAL '3 hours', NOW()
    )`,
    [testAppId, testJobId]
  );
}

async function cleanupTestData() {
  await query("DELETE FROM job_applications WHERE id = $1", [testAppId]);
  await query("DELETE FROM freelance_leads WHERE id = $1", [testLeadId]);
  await query("DELETE FROM jobs WHERE id = $1", [testJobId]);
}

beforeEach(async () => {
  resetAssistantAuthLimiter();
  config.assistantApiKey = TEST_KEY;
});

afterAll(async () => {
  await cleanupTestData();
  await pool.end();
});

describe('Assistant API: Authentication & Security', () => {
  it('rejects requests without Authorization header with 401', async () => {
    const res = await request(app).get('/api/v1/assistant/summary');
    expect(res.status).toBe(401);
    expect(res.body).toMatchObject({
      success: false,
      error: { code: 'UNAUTHORIZED' },
    });
  });

  it('rejects requests with malformed Authorization header with 401', async () => {
    const res = await request(app)
      .get('/api/v1/assistant/summary')
      .set('Authorization', 'Basic invalid_token');
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe('UNAUTHORIZED');
  });

  it('rejects requests with wrong token with 401 and never echoes the secret', async () => {
    const res = await request(app)
      .get('/api/v1/assistant/summary')
      .set('Authorization', 'Bearer wrong_assistant_token_9999');
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe('UNAUTHORIZED');
    expect(JSON.stringify(res.body)).not.toContain(TEST_KEY);
    expect(JSON.stringify(res.body)).not.toContain('wrong_assistant_token_9999');
  });

  it('fails closed with 503 if server-side ASSISTANT_API_KEY is not configured', async () => {
    config.assistantApiKey = '';
    const res = await request(app)
      .get('/api/v1/assistant/summary')
      .set('Authorization', `Bearer ${TEST_KEY}`);
    expect(res.status).toBe(503);
    expect(res.body.error.code).toBe('ASSISTANT_NOT_CONFIGURED');
  });

  it('allows access with valid credentials on health endpoint', async () => {
    const res = await request(app)
      .get('/api/v1/assistant/health')
      .set(authHeader);
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({
      success: true,
      status: 'ok',
      database: 'connected',
      access: 'read_only',
    });
  });
});

describe('Assistant API: Endpoints & Data Sanitization', () => {
  beforeAll(async () => {
    await cleanupTestData();
    await seedTestData();
  });

  afterAll(async () => {
    await cleanupTestData();
  });

  describe('GET /api/v1/assistant/jobs', () => {
    it('returns sanitized jobs with correct fields and never leaks raw_data', async () => {
      const res = await request(app)
        .get('/api/v1/assistant/jobs')
        .set(authHeader);
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.jobs)).toBe(true);
      expect(res.body.jobs.length).toBeGreaterThanOrEqual(1);

      const job = res.body.jobs.find((j: any) => j.id === testJobId);
      expect(job).toBeDefined();
      expect(job.title).toBe('Backend Engineer Java');
      expect(job.company).toBe('TestCorp');
      expect(job.matchScore).toBe(92);
      expect(job.status).toBe('OPEN');
      expect(job.skills).toContain('Java');

      // Crucial security check: raw_data and internal secrets must never be present
      expect(job.raw_data).toBeUndefined();
      expect(JSON.stringify(res.body)).not.toContain('secret_123');
    });

    it('filters jobs by min_score, status, and duration since', async () => {
      const res = await request(app)
        .get('/api/v1/assistant/jobs?min_score=90&status=OPEN&since=24h')
        .set(authHeader);
      expect(res.status).toBe(200);
      expect(res.body.jobs.every((j: any) => j.matchScore >= 90)).toBe(true);
      expect(res.body.jobs.every((j: any) => j.status === 'OPEN')).toBe(true);
    });

    it('rejects invalid limit exceeding maximum', async () => {
      const res = await request(app)
        .get('/api/v1/assistant/jobs?limit=500')
        .set(authHeader);
      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe('VALIDATION_ERROR');
    });
  });

  describe('GET /api/v1/assistant/freelance', () => {
    it('returns sanitized freelance leads without leaking raw_data', async () => {
      const res = await request(app)
        .get('/api/v1/assistant/freelance')
        .set(authHeader);
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.leads)).toBe(true);

      const lead = res.body.leads.find((l: any) => l.id === testLeadId);
      expect(lead).toBeDefined();
      expect(lead.title).toBe('Spring Boot API Migration');
      expect(lead.platform).toBe('Upwork');
      expect(lead.budget).toBe(1500);
      expect(lead.matchScore).toBe(88);

      // Security: raw_data / confidential contact must not be exposed
      expect(lead.raw_data).toBeUndefined();
      expect(JSON.stringify(res.body)).not.toContain('confidential');
    });

    it('filters freelance leads by platform and min_score', async () => {
      const res = await request(app)
        .get('/api/v1/assistant/freelance?platform=Upwork&min_score=80')
        .set(authHeader);
      expect(res.status).toBe(200);
      expect(res.body.leads.every((l: any) => l.platform.toLowerCase() === 'upwork')).toBe(true);
    });
  });

  describe('GET /api/v1/assistant/applications', () => {
    it('returns sanitized applications and omits internal private resume IDs and recruiter contacts', async () => {
      const res = await request(app)
        .get('/api/v1/assistant/applications')
        .set(authHeader);
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.applications)).toBe(true);

      const application = res.body.applications.find((a: any) => a.id === testAppId);
      expect(application).toBeDefined();
      expect(application.company).toBe('TestCorp');
      expect(application.role).toBe('Backend Engineer');
      expect(application.status).toBe('interviewing');

      // Security: private resume IDs or raw recruiter contact must not be exposed
      expect(application.resume_id).toBeUndefined();
      expect(application.recruiter_contact).toBeUndefined();
      expect(JSON.stringify(res.body)).not.toContain('res-priv-99');
    });

    it('filters applications by status', async () => {
      const res = await request(app)
        .get('/api/v1/assistant/applications?status=interviewing')
        .set(authHeader);
      expect(res.status).toBe(200);
      expect(res.body.applications.every((a: any) => a.status === 'interviewing')).toBe(true);
    });
  });

  describe('GET /api/v1/assistant/summary', () => {
    it('returns real aggregate statistics for the requested period', async () => {
      const res = await request(app)
        .get('/api/v1/assistant/summary?since=24h')
        .set(authHeader);
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.period).toBeDefined();

      expect(typeof res.body.jobs.new).toBe('number');
      expect(typeof res.body.jobs.open).toBe('number');
      expect(typeof res.body.jobs.highMatch).toBe('number');
      expect(typeof res.body.jobs.saved).toBe('number');

      expect(typeof res.body.freelance.new).toBe('number');
      expect(typeof res.body.freelance.open).toBe('number');
      expect(typeof res.body.freelance.highMatch).toBe('number');

      expect(typeof res.body.applications.submitted).toBe('number');
      expect(typeof res.body.applications.pending).toBe('number');
      expect(typeof res.body.applications.needsFollowUp).toBe('number');
      expect(typeof res.body.applications.responses).toBe('number');

      // Verify seed item was captured in summary
      expect(res.body.jobs.open).toBeGreaterThanOrEqual(1);
      expect(res.body.jobs.saved).toBeGreaterThanOrEqual(1);
      expect(res.body.freelance.open).toBeGreaterThanOrEqual(1);
    });

    it('handles empty intervals gracefully returning zero counts rather than failing', async () => {
      // Future window where no entries exist
      const res = await request(app)
        .get('/api/v1/assistant/summary?since=2099-01-01T00:00:00Z&until=2099-01-02T00:00:00Z')
        .set(authHeader);
      expect(res.status).toBe(200);
      expect(res.body.jobs.new).toBe(0);
      expect(res.body.freelance.new).toBe(0);
      expect(res.body.applications.submitted).toBe(0);
    });
  });
});
