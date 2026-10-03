import { NextFunction, Request, Response } from 'express';
import { z } from 'zod';
import { logger } from '../../utils/logger';
import { JobSyncService } from './job-sync.service';
import { jobSyncRepository } from './job-sync.repository';

const bodySchema = z
  .object({
    dryRun: z.boolean().optional(),
    providers: z.array(z.enum(['greenhouse', 'lever', 'ashby', 'remoteok', 'weworkremotely'])).max(5).optional(),
  })
  .strict();

const STALE_AFTER_MS = 3 * 60 * 60 * 1000; // hourly job: unhealthy if nothing succeeded for 3h

let service: JobSyncService | null = null;
/** Lazy so env changes (tests) and config errors surface per request, not at import time. */
export function getJobSyncService(): JobSyncService {
  return (service ??= new JobSyncService());
}
export function setJobSyncServiceForTests(s: JobSyncService | null): void {
  service = s;
}

export class JobSyncController {
  async triggerSync(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const body = bodySchema.parse(req.body ?? {});
      const svc = getJobSyncService();
      const opts = { trigger: 'http' as const, dryRun: body.dryRun, providers: body.providers };

      // wait=false: acknowledge immediately and keep running (for hosts with short proxy timeouts).
      if (req.query.wait === 'false') {
        void svc.run(opts).catch((err) => logger.error('Background sync failed', { error: err instanceof Error ? err.message : 'error' }));
        res.status(202).json({ success: true, data: { accepted: true } });
        return;
      }

      const summary = await svc.run(opts);
      if (summary.status === 'SKIPPED_LOCKED') {
        res.status(409).json({
          success: false,
          error: { code: 'SYNC_IN_PROGRESS', message: 'Another sync is already running; this request exited safely.', details: [] },
          data: summary,
        });
        return;
      }
      // Total failure must be visible to the scheduler; partial success is a 200.
      res.status(summary.status === 'FAILED' ? 502 : 200).json({ success: summary.status !== 'FAILED', data: summary });
    } catch (err) {
      next(err);
    }
  }

  async getStatus(_req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const [last, lastOk, counts, recent] = await Promise.all([
        jobSyncRepository.latestRun(),
        jobSyncRepository.latestRun(true),
        jobSyncRepository.statusCounts(),
        jobSyncRepository.recentRuns(10),
      ]);
      const lastOkAt: Date | null = lastOk?.completed_at ?? null;
      res.status(200).json({
        success: true,
        data: {
          lastSync: last?.completed_at ?? last?.started_at ?? null,
          status: last?.status ?? 'NEVER_RUN',
          jobsDiscovered: last?.received_count ?? 0,
          jobsInserted: last?.inserted_count ?? 0,
          jobsUpdated: last?.updated_count ?? 0,
          jobsDeduplicated: last?.duplicate_count ?? 0,
          jobsRejected: last?.rejected_count ?? 0,
          errorSummary: last?.error_message ?? null,
          providers: last?.metadata?.providers ?? [],
          lastSuccessfulSync: lastOkAt,
          healthy: lastOkAt !== null && Date.now() - new Date(lastOkAt).getTime() < STALE_AFTER_MS,
          jobsByStatus: counts,
          recentRuns: recent,
        },
      });
    } catch (err) {
      next(err);
    }
  }
}

export const jobSyncController = new JobSyncController();
