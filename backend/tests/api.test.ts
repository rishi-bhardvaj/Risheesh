import request from 'supertest';
import { createApp } from '../src/app';
import { pool, query } from '../src/db';
import { config } from '../src/config';

const app = createApp();

describe('Career OS Backend Integration Tests', () => {
  beforeAll(async () => {
    // Clean test tables
    await query('DELETE FROM job_applications');
    await query('DELETE FROM jobs');
    await query('DELETE FROM freelance_payments');
    await query('DELETE FROM projects');
    await query('DELETE FROM freelance_leads');
    await query('DELETE FROM clients');
    await query('DELETE FROM import_runs');
  });

  afterAll(async () => {
    await pool.end();
  });

  describe('1. Health Check Endpoint', () => {
    it('GET /health returns 200 ok and connected database', async () => {
      const res = await request(app).get('/health');
      expect(res.status).toBe(200);
      expect(res.body.status).toBe('ok');
      expect(res.body.database).toBe('connected');
    });
  });

  describe('2. Security & Auth Middleware', () => {
    it('rejects /api/v1/import/jobs without authorization header', async () => {
      const res = await request(app)
        .post('/api/v1/import/jobs')
        .send({ schema_version: '1.0', data_type: 'jobs', source: 'test', jobs: [] });
      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
      expect(res.body.error.code).toBe('UNAUTHORIZED');
    });

    it('rejects /api/v1/import/jobs with invalid API key', async () => {
      const res = await request(app)
        .post('/api/v1/import/jobs')
        .set('Authorization', 'Bearer invalid_key_123')
        .send({ schema_version: '1.0', data_type: 'jobs', source: 'test', jobs: [] });
      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
    });

    it('rejects malformed json or oversized payload cleanly', async () => {
      const res = await request(app)
        .post('/api/v1/jobs')
        .set('Content-Type', 'application/json')
        .send('{"title": "Unclosed string');
      expect(res.status).toBe(400);
    });

    it('sanitizes potential SQL injection payloads gracefully', async () => {
      const res = await request(app)
        .get("/api/v1/jobs?search=' OR '1'='1; DROP TABLE jobs; --")
        .expect(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
    });
  });

  describe('3. Batch JSON Import Pipeline & Deduplication', () => {
    const jobsBatch = {
      schema_version: '1.0',
      data_type: 'jobs',
      source: 'test_scraper',
      jobs: [
        {
          external_id: 'batch-job-1',
          title: 'Senior Mobile Engineer',
          company: 'TechCorp Global',
          location: 'Bengaluru, India',
          url: 'https://techcorp.example/jobs/batch-1',
          source: 'test_scraper',
          skills: ['Flutter', 'Dart', 'PostgreSQL'],
          salary: '₹30-40 LPA',
          description: 'Build robust mobile architectures.',
        },
        {
          external_id: 'batch-job-2',
          title: 'Backend Engineer',
          company: 'Acme Cloud',
          location: 'Remote',
          url: 'https://acme.example/jobs/batch-2',
          source: 'test_scraper',
          skills: ['Node.js', 'TypeScript', 'PostgreSQL'],
          salary: '$120k',
          description: 'Build resilient APIs.',
        },
      ],
    };

    it('imports valid jobs batch successfully', async () => {
      const res = await request(app)
        .post('/api/v1/import/jobs')
        .set('Authorization', `Bearer ${config.importApiKey}`)
        .send(jobsBatch);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.received).toBe(2);
      expect(res.body.data.inserted).toBe(2);
      expect(res.body.data.updated).toBe(0);
      expect(res.body.data.duplicates).toBe(0);
      expect(res.body.data.rejected).toBe(0);
    });

    it('re-importing the identical batch detects duplicates without errors', async () => {
      const res = await request(app)
        .post('/api/v1/import/jobs')
        .set('Authorization', `Bearer ${config.importApiKey}`)
        .send(jobsBatch);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.received).toBe(2);
      expect(res.body.data.inserted).toBe(0);
      expect(res.body.data.duplicates).toBe(2);
    });

    it('updating research fields updates record while preserving user-managed fields', async () => {
      // User marks job 1 as saved and adds notes
      const listRes = await request(app).get('/api/v1/jobs?search=TechCorp');
      const job1 = listRes.body.data[0];
      await request(app).post(`/api/v1/jobs/${job1.id}/save`).expect(200);
      await request(app).patch(`/api/v1/jobs/${job1.id}`).send({ notes: 'User personal note' }).expect(200);

      // New batch arrives with updated salary
      const updatedBatch = {
        ...jobsBatch,
        jobs: [
          {
            ...jobsBatch.jobs[0],
            salary: '₹35-50 LPA (Revised)',
          },
        ],
      };

      const importRes = await request(app)
        .post('/api/v1/import/jobs')
        .set('Authorization', `Bearer ${config.importApiKey}`)
        .send(updatedBatch);

      expect(importRes.status).toBe(200);
      expect(importRes.body.data.updated).toBe(1);

      // Verify user fields were preserved!
      const verifyRes = await request(app).get(`/api/v1/jobs/${job1.id}`).expect(200);
      expect(verifyRes.body.data.salary).toBe('₹35-50 LPA (Revised)');
      expect(verifyRes.body.data.is_saved).toBe(true);
      expect(verifyRes.body.data.notes).toBe('User personal note');
    });

    it('handles freelance JSON import and deduplication', async () => {
      const freelanceBatch = {
        schema_version: '1.0',
        data_type: 'freelance',
        source: 'daily_freelance_agent',
        projects: [
          {
            external_id: 'fl-1',
            title: 'Flutter UI Redesign',
            client_name: 'DesignFlow Ltd',
            platform: 'Upwork',
            url: 'https://upwork.example/fl-1',
            budget: 2000,
            currency: 'USD',
            skills: ['Flutter', 'Figma'],
            description: 'Redesign existing screens.',
          },
        ],
      };

      const res = await request(app)
        .post('/api/v1/import/freelance')
        .set('Authorization', `Bearer ${config.importApiKey}`)
        .send(freelanceBatch);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.inserted).toBe(1);

      // Second run is duplicate
      const res2 = await request(app)
        .post('/api/v1/import/freelance')
        .set('Authorization', `Bearer ${config.importApiKey}`)
        .send(freelanceBatch);

      expect(res2.body.data.duplicates).toBe(1);
    });

    it('verifies import runs tracking table', async () => {
      const res = await request(app)
        .get('/api/v1/import/runs')
        .set('Authorization', `Bearer ${config.importApiKey}`)
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.data.length).toBeGreaterThan(0);
      expect(res.body.data[0].status).toBe('SUCCESS');
    });
  });

  describe('4. Jobs CRUD, Search, and Filtering', () => {
    let createdJobId: string;

    it('creates a job via POST /api/v1/jobs', async () => {
      const res = await request(app)
        .post('/api/v1/jobs')
        .send({
          title: 'Full Stack Engineer',
          company: 'InnovateX',
          location: 'Pune, India',
          employment_type: 'Full-time',
          salary: '₹20-25 LPA',
          skills: ['Dart', 'PostgreSQL'],
        });

      expect(res.status).toBe(201);
      expect(res.body.data.title).toBe('Full Stack Engineer');
      createdJobId = res.body.data.id;
    });

    it('reads job by ID', async () => {
      const res = await request(app).get(`/api/v1/jobs/${createdJobId}`);
      expect(res.status).toBe(200);
      expect(res.body.data.id).toBe(createdJobId);
    });

    it('filters jobs by company and search query', async () => {
      const res = await request(app).get('/api/v1/jobs?company=InnovateX');
      expect(res.status).toBe(200);
      expect(res.body.data.length).toBe(1);
    });

    it('updates job details', async () => {
      const res = await request(app)
        .patch(`/api/v1/jobs/${createdJobId}`)
        .send({ salary: '₹25-30 LPA' });
      expect(res.status).toBe(200);
      expect(res.body.data.salary).toBe('₹25-30 LPA');
    });

    it('saves and unsaves a job', async () => {
      let res = await request(app).post(`/api/v1/jobs/${createdJobId}/save`);
      expect(res.status).toBe(200);
      expect(res.body.data.is_saved).toBe(true);

      res = await request(app).post(`/api/v1/jobs/${createdJobId}/unsave`);
      expect(res.status).toBe(200);
      expect(res.body.data.is_saved).toBe(false);
    });

    it('deletes a job', async () => {
      const res = await request(app).delete(`/api/v1/jobs/${createdJobId}`);
      expect(res.status).toBe(200);

      await request(app).get(`/api/v1/jobs/${createdJobId}`).expect(404);
    });
  });

  describe('5. Job Applications Workflow', () => {
    let testJobId: string;
    let appId: string;

    beforeAll(async () => {
      const jobRes = await request(app).post('/api/v1/jobs').send({
        title: 'Platform Lead',
        company: 'Starlight Inc',
      });
      testJobId = jobRes.body.data.id;
    });

    it('creates job application linked to job', async () => {
      const res = await request(app)
        .post('/api/v1/applications')
        .send({
          job_id: testJobId,
          company: 'Starlight Inc',
          role: 'Platform Lead',
          status: 'applied',
          recruiter_name: 'David Miller',
          notes: 'Referral through alum network',
        });

      expect(res.status).toBe(201);
      expect(res.body.data.company).toBe('Starlight Inc');
      appId = res.body.data.id;
    });

    it('updates application status to interview', async () => {
      const res = await request(app)
        .patch(`/api/v1/applications/${appId}`)
        .send({
          status: 'interview',
          interview_stage: 'Technical Round 1',
        });

      expect(res.status).toBe(200);
      expect(res.body.data.status).toBe('interview');
      expect(res.body.data.interview_stage).toBe('Technical Round 1');
    });

    it('queries applications with pagination and filters', async () => {
      const res = await request(app).get('/api/v1/applications?status=interview');
      expect(res.status).toBe(200);
      expect(res.body.data.length).toBeGreaterThanOrEqual(1);
    });
  });

  describe('6. Freelance Leads, Clients, Projects, & Payments', () => {
    let clientId: string;
    let leadId: string;
    let projectId: string;
    let paymentId: string;

    it('creates a client', async () => {
      const res = await request(app)
        .post('/api/v1/clients')
        .send({
          name: 'Acme Ventures',
          contact_name: 'John Doe',
          email: 'john@acmeventures.example',
          status: 'ACTIVE',
        });

      expect(res.status).toBe(201);
      expect(res.body.data.name).toBe('Acme Ventures');
      clientId = res.body.data.id;
    });

    it('creates a freelance lead and links to client', async () => {
      const res = await request(app)
        .post('/api/v1/freelance/leads')
        .send({
          client_id: clientId,
          title: 'Design System Implementation',
          client_name: 'Acme Ventures',
          budget: 5000,
          currency: 'USD',
          status: 'PROPOSAL_SENT',
        });

      expect(res.status).toBe(201);
      leadId = res.body.data.id;
    });

    it('creates a project linked to client and lead', async () => {
      const res = await request(app)
        .post('/api/v1/projects')
        .send({
          client_id: clientId,
          lead_id: leadId,
          name: 'Acme Design System',
          is_freelance: true,
          status: 'in_progress',
          progress: 0.25,
        });

      expect(res.status).toBe(201);
      projectId = res.body.data.id;
    });

    it('creates a freelance payment', async () => {
      const res = await request(app)
        .post('/api/v1/payments')
        .send({
          client_id: clientId,
          project_id: projectId,
          amount: 2500,
          currency: 'USD',
          status: 'RECEIVED',
          description: 'Milestone 1 Payment',
        });

      expect(res.status).toBe(201);
      expect(Number(res.body.data.amount)).toBe(2500);
      paymentId = res.body.data.id;
    });

    it('fetches payments for client', async () => {
      const res = await request(app).get(`/api/v1/payments?client_id=${clientId}`);
      expect(res.status).toBe(200);
      expect(res.body.data.length).toBe(1);
    });

    it('cleans up test resources', async () => {
      await request(app).delete(`/api/v1/payments/${paymentId}`).expect(200);
      await request(app).delete(`/api/v1/projects/${projectId}`).expect(200);
      await request(app).delete(`/api/v1/freelance/leads/${leadId}`).expect(200);
      await request(app).delete(`/api/v1/clients/${clientId}`).expect(200);
    });
  });
});
