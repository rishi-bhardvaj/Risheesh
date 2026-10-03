import { Router, Request, Response, NextFunction } from 'express';
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
v1.post('/import/jobs', requireImportAuth, (req: Request, res: Response, next: NextFunction) => importController.importJobs(req, res, next));
v1.post('/import/freelance', requireImportAuth, (req: Request, res: Response, next: NextFunction) => importController.importFreelance(req, res, next));
v1.get('/import/runs', requireImportAuth, (req: Request, res: Response, next: NextFunction) => importController.getImportRuns(req, res, next));

// --- Internal job sync (scheduler/CLI; protected with JOB_SYNC_SECRET) ---
v1.post('/internal/jobs/sync', requireJobSyncAuth, (req: Request, res: Response, next: NextFunction) => jobSyncController.triggerSync(req, res, next));
v1.get('/internal/jobs/sync/status', requireJobSyncAuth, (req: Request, res: Response, next: NextFunction) => jobSyncController.getStatus(req, res, next));

// --- Jobs Endpoints ---
v1.get('/jobs', (req: Request, res: Response, next: NextFunction) => jobsController.getJobs(req, res, next));
v1.get('/jobs/:id', (req: Request, res: Response, next: NextFunction) => jobsController.getJob(req, res, next));
v1.post('/jobs', (req: Request, res: Response, next: NextFunction) => jobsController.createJob(req, res, next));
v1.patch('/jobs/:id', (req: Request, res: Response, next: NextFunction) => jobsController.updateJob(req, res, next));
v1.delete('/jobs/:id', (req: Request, res: Response, next: NextFunction) => jobsController.deleteJob(req, res, next));
v1.post('/jobs/:id/save', (req: Request, res: Response, next: NextFunction) => jobsController.saveJob(req, res, next));
v1.post('/jobs/:id/unsave', (req: Request, res: Response, next: NextFunction) => jobsController.unsaveJob(req, res, next));

// --- Job Applications Endpoints ---
v1.get('/applications', (req: Request, res: Response, next: NextFunction) => applicationsController.getApplications(req, res, next));
v1.get('/applications/:id', (req: Request, res: Response, next: NextFunction) => applicationsController.getApplication(req, res, next));
v1.post('/applications', (req: Request, res: Response, next: NextFunction) => applicationsController.createApplication(req, res, next));
v1.patch('/applications/:id', (req: Request, res: Response, next: NextFunction) => applicationsController.updateApplication(req, res, next));
v1.delete('/applications/:id', (req: Request, res: Response, next: NextFunction) => applicationsController.deleteApplication(req, res, next));

// --- Freelance Leads Endpoints ---
v1.get('/freelance/leads', (req: Request, res: Response, next: NextFunction) => freelanceController.getLeads(req, res, next));
v1.get('/freelance/leads/:id', (req: Request, res: Response, next: NextFunction) => freelanceController.getLead(req, res, next));
v1.post('/freelance/leads', (req: Request, res: Response, next: NextFunction) => freelanceController.createLead(req, res, next));
v1.patch('/freelance/leads/:id', (req: Request, res: Response, next: NextFunction) => freelanceController.updateLead(req, res, next));
v1.delete('/freelance/leads/:id', (req: Request, res: Response, next: NextFunction) => freelanceController.deleteLead(req, res, next));

// --- Clients Endpoints ---
v1.get('/clients', (req: Request, res: Response, next: NextFunction) => clientsController.getClients(req, res, next));
v1.get('/clients/:id', (req: Request, res: Response, next: NextFunction) => clientsController.getClient(req, res, next));
v1.post('/clients', (req: Request, res: Response, next: NextFunction) => clientsController.createClient(req, res, next));
v1.patch('/clients/:id', (req: Request, res: Response, next: NextFunction) => clientsController.updateClient(req, res, next));
v1.delete('/clients/:id', (req: Request, res: Response, next: NextFunction) => clientsController.deleteClient(req, res, next));

// --- Projects Endpoints ---
v1.get('/projects', (req: Request, res: Response, next: NextFunction) => projectsController.getProjects(req, res, next));
v1.get('/projects/:id', (req: Request, res: Response, next: NextFunction) => projectsController.getProject(req, res, next));
v1.post('/projects', (req: Request, res: Response, next: NextFunction) => projectsController.createProject(req, res, next));
v1.patch('/projects/:id', (req: Request, res: Response, next: NextFunction) => projectsController.updateProject(req, res, next));
v1.delete('/projects/:id', (req: Request, res: Response, next: NextFunction) => projectsController.deleteProject(req, res, next));

// --- Payments Endpoints ---
v1.get('/payments', (req: Request, res: Response, next: NextFunction) => paymentsController.getPayments(req, res, next));
v1.get('/payments/:id', (req: Request, res: Response, next: NextFunction) => paymentsController.getPayment(req, res, next));
v1.post('/payments', (req: Request, res: Response, next: NextFunction) => paymentsController.createPayment(req, res, next));
v1.patch('/payments/:id', (req: Request, res: Response, next: NextFunction) => paymentsController.updatePayment(req, res, next));
v1.delete('/payments/:id', (req: Request, res: Response, next: NextFunction) => paymentsController.deletePayment(req, res, next));

// Mount v1 router at /api/v1
router.use('/api/v1', v1);

export default router;
