import { Router, Request, Response } from 'express';
import { checkDatabaseConnection } from '../db';
import { requireImportAuth } from '../middleware/auth';
import { requireJobSyncAuth } from '../middleware/jobSyncAuth';
import { jobSyncController } from '../modules/job-sync/job-sync.controller';
import { importController } from '../modules/imports/import.controller';
import { jobsController } from '../modules/jobs/jobs.controller';
import { applicationsController } from '../modules/applications/applications.controller';
import { freelanceController } from '../modules/freelance/freelance.controller';
import { clientsController } from '../modules/clients/clients.controller';
import { projectsController } from '../modules/projects/projects.controller';
import { paymentsController } from '../modules/payments/payments.controller';

const router = Router();

// Health Check (Requirement #47)
router.get('/health', async (_req: Request, res: Response) => {
  const dbConnected = await checkDatabaseConnection();
  if (dbConnected) {
    res.status(200).json({
      status: 'ok',
      database: 'connected',
    });
  } else {
    res.status(503).json({
      status: 'error',
      database: 'disconnected',
    });
  }
});

const v1 = Router();

// --- Import Endpoints (Protected with IMPORT_API_KEY) ---
v1.post('/import/jobs', requireImportAuth, (req, res, next) => importController.importJobs(req, res, next));
v1.post('/import/freelance', requireImportAuth, (req, res, next) => importController.importFreelance(req, res, next));
v1.get('/import/runs', requireImportAuth, (req, res, next) => importController.getImportRuns(req, res, next));

// --- Internal job sync (scheduler/CLI; protected with JOB_SYNC_SECRET) ---
v1.post('/internal/jobs/sync', requireJobSyncAuth, (req, res, next) => jobSyncController.triggerSync(req, res, next));
v1.get('/internal/jobs/sync/status', requireJobSyncAuth, (req, res, next) => jobSyncController.getStatus(req, res, next));

// --- Jobs Endpoints ---
v1.get('/jobs', (req, res, next) => jobsController.getJobs(req, res, next));
v1.get('/jobs/:id', (req, res, next) => jobsController.getJob(req, res, next));
v1.post('/jobs', (req, res, next) => jobsController.createJob(req, res, next));
v1.patch('/jobs/:id', (req, res, next) => jobsController.updateJob(req, res, next));
v1.delete('/jobs/:id', (req, res, next) => jobsController.deleteJob(req, res, next));
v1.post('/jobs/:id/save', (req, res, next) => jobsController.saveJob(req, res, next));
v1.post('/jobs/:id/unsave', (req, res, next) => jobsController.unsaveJob(req, res, next));

// --- Job Applications Endpoints ---
v1.get('/applications', (req, res, next) => applicationsController.getApplications(req, res, next));
v1.get('/applications/:id', (req, res, next) => applicationsController.getApplication(req, res, next));
v1.post('/applications', (req, res, next) => applicationsController.createApplication(req, res, next));
v1.patch('/applications/:id', (req, res, next) => applicationsController.updateApplication(req, res, next));
v1.delete('/applications/:id', (req, res, next) => applicationsController.deleteApplication(req, res, next));

// --- Freelance Leads Endpoints ---
v1.get('/freelance/leads', (req, res, next) => freelanceController.getLeads(req, res, next));
v1.get('/freelance/leads/:id', (req, res, next) => freelanceController.getLead(req, res, next));
v1.post('/freelance/leads', (req, res, next) => freelanceController.createLead(req, res, next));
v1.patch('/freelance/leads/:id', (req, res, next) => freelanceController.updateLead(req, res, next));
v1.delete('/freelance/leads/:id', (req, res, next) => freelanceController.deleteLead(req, res, next));

// --- Clients Endpoints ---
v1.get('/clients', (req, res, next) => clientsController.getClients(req, res, next));
v1.get('/clients/:id', (req, res, next) => clientsController.getClient(req, res, next));
v1.post('/clients', (req, res, next) => clientsController.createClient(req, res, next));
v1.patch('/clients/:id', (req, res, next) => clientsController.updateClient(req, res, next));
v1.delete('/clients/:id', (req, res, next) => clientsController.deleteClient(req, res, next));

// --- Projects Endpoints ---
v1.get('/projects', (req, res, next) => projectsController.getProjects(req, res, next));
v1.get('/projects/:id', (req, res, next) => projectsController.getProject(req, res, next));
v1.post('/projects', (req, res, next) => projectsController.createProject(req, res, next));
v1.patch('/projects/:id', (req, res, next) => projectsController.updateProject(req, res, next));
v1.delete('/projects/:id', (req, res, next) => projectsController.deleteProject(req, res, next));

// --- Payments Endpoints ---
v1.get('/payments', (req, res, next) => paymentsController.getPayments(req, res, next));
v1.get('/payments/:id', (req, res, next) => paymentsController.getPayment(req, res, next));
v1.post('/payments', (req, res, next) => paymentsController.createPayment(req, res, next));
v1.patch('/payments/:id', (req, res, next) => paymentsController.updatePayment(req, res, next));
v1.delete('/payments/:id', (req, res, next) => paymentsController.deletePayment(req, res, next));

// Mount v1 router at /api/v1
router.use('/api/v1', v1);

export default router;
