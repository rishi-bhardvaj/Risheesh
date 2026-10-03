import { randomUUID } from 'crypto';
import { logger, redact } from '../../utils/logger';
import { HttpClient } from './http';
import { JobMatchingService } from './job-matching.service';
import { normalizeJob } from './job-normalization.service';
import { JobSyncConfig, loadJobSyncConfig } from './job-sync.config';
import { JobSyncRepository, jobSyncRepository } from './job-sync.repository';
import { ALLOWED_HOSTS, enabledProviders } from './providers';
import type { JobProvider, ProviderFetchResult, ProviderRunReport, SyncStatus, SyncSummary } from './types';

export interface RunOptions {
  trigger: 'http' | 'cli' | 'verify' | 'test';
  /** Fetch + filter only: no lock, no run row, nothing written. */
  dryRun?: boolean;
  /** Restrict to these provider ids. */
  providers?: string[];
}

export interface JobSyncDeps {
  cfg?: JobSyncConfig;
  repo?: JobSyncRepository;
  providers?: JobProvider[];
  http?: HttpClient;
}

const emptySummary = (dryRun: boolean, status: SyncStatus): SyncSummary => ({
  runId: null,
  status,
  startedAt: new Date().toISOString(),
  completedAt: null,
  dryRun,
  providersAttempted: 0,
  providersSucceeded: 0,
  providersFailed: 0,
  jobsDiscovered: 0,
  jobsAccepted: 0,
  jobsInserted: 0,
  jobsUpdated: 0,
  jobsSkipped: 0,
  jobsDeduplicated: 0,
  jobsRejected: 0,
  jobsMarkedStale: 0,
  jobsMarkedClosed: 0,
  rejectionReasons: {},
  providers: [],
  errorSummary: null,
});

type Fetched =
  | { ok: true; provider: JobProvider; result: ProviderFetchResult; ms: number }
  | { ok: false; provider: JobProvider; error: string; ms: number };

/**
 * The one canonical sync implementation. The HTTP endpoint, the `jobs:sync` CLI and the
 * verify script all call run().
 */
export class JobSyncService {
  private readonly cfg: JobSyncConfig;
  private readonly repo: JobSyncRepository;
  private readonly providers: JobProvider[];
  private readonly http: HttpClient;
  private readonly matcher: JobMatchingService;

  constructor(deps: JobSyncDeps = {}) {
    this.cfg = deps.cfg ?? loadJobSyncConfig();
    this.repo = deps.repo ?? jobSyncRepository;
    this.providers = deps.providers ?? enabledProviders(this.cfg);
    this.http = deps.http ?? new HttpClient(this.cfg.http, ALLOWED_HOSTS);
    this.matcher = new JobMatchingService(this.cfg);
  }

  get providerIds(): string[] {
    return this.providers.map((p) => p.id);
  }

  async run(opts: RunOptions): Promise<SyncSummary> {
    const dryRun = opts.dryRun === true;
    const providers = this.providers.filter((p) => !opts.providers || opts.providers.includes(p.id));
    const summary = emptySummary(dryRun, 'IN_PROGRESS');

    const owner = randomUUID();
    if (!dryRun) {
      const locked = await this.repo.acquireLock(owner, this.cfg.lockTtlSeconds);
      if (!locked) {
        logger.warn('Sync skipped: another sync holds the lock');
        return { ...summary, status: 'SKIPPED_LOCKED', completedAt: new Date().toISOString() };
      }
    }

    // Stop before the lease can expire so two runs can never overlap.
    const deadline = new AbortController();
    const deadlineTimer = setTimeout(() => deadline.abort(), Math.max(10, this.cfg.lockTtlSeconds - 30) * 1000);
    deadlineTimer.unref?.();

    try {
      if (!dryRun) {
        const abandoned = await this.repo.abandonStaleRuns();
        if (abandoned > 0) logger.warn(`Marked ${abandoned} abandoned sync run(s) as FAILED`);
        summary.runId = await this.repo.createRun(opts.trigger);
      }
      logger.info('Sync started', { runId: summary.runId, providers: providers.map((p) => p.id), dryRun });

      // Providers fetch concurrently and independently (allSettled semantics via fetchOne).
      const fetched = await Promise.all(providers.map((p) => this.fetchOne(p, deadline.signal)));

      const seen = new Set<string>();
      const coveredSources: string[] = [];

      for (const f of fetched) {
        const report = await this.processProvider(f, seen, dryRun, summary);
        summary.providers.push(report);
        if (report.status !== 'FAILED') summary.providersSucceeded++;
        else summary.providersFailed++;
        if (report.fullyCovered) coveredSources.push(f.provider.source);
        if (!dryRun) await this.repo.renewLock(owner, this.cfg.lockTtlSeconds);
      }
      summary.providersAttempted = providers.length;

      if (!dryRun) {
        const fr = await this.repo.applyFreshness(coveredSources, this.cfg.staleAfterHours, this.cfg.closeAfterDays);
        summary.jobsMarkedStale = fr.stale;
        summary.jobsMarkedClosed = fr.closed;
      }

      const allClean = summary.providers.length > 0 && summary.providers.every((p) => p.status === 'SUCCESS');
      summary.status = allClean ? 'SUCCESS' : summary.providersSucceeded > 0 ? 'PARTIAL_SUCCESS' : 'FAILED';
      const errs = summary.providers.filter((p) => p.errors.length > 0).map((p) => `${p.provider}: ${p.errors[0]}`);
      if (providers.length === 0) errs.push('No providers enabled');
      summary.errorSummary = errs.length ? errs.join(' | ').slice(0, 1000) : null;
      summary.completedAt = new Date().toISOString();

      if (summary.runId) await this.repo.finishRun(summary.runId, summary);
      logger.info('Sync finished', {
        status: summary.status,
        discovered: summary.jobsDiscovered,
        inserted: summary.jobsInserted,
        updated: summary.jobsUpdated,
        rejected: summary.jobsRejected,
      });
      return summary;
    } catch (err) {
      summary.status = 'FAILED';
      summary.completedAt = new Date().toISOString();
      summary.errorSummary = redact(err instanceof Error ? err.message : 'Unknown error').slice(0, 500);
      logger.error('Sync crashed', { error: summary.errorSummary });
      if (summary.runId) await this.repo.finishRun(summary.runId, summary).catch(() => undefined);
      throw err;
    } finally {
      clearTimeout(deadlineTimer);
      if (!dryRun) await this.repo.releaseLock(owner).catch(() => undefined);
    }
  }

  private async fetchOne(provider: JobProvider, parent: AbortSignal): Promise<Fetched> {
    const started = Date.now();
    const ac = new AbortController();
    const onParentAbort = () => ac.abort();
    parent.addEventListener('abort', onParentAbort, { once: true });
    let timer: NodeJS.Timeout | undefined;
    try {
      const timeout = new Promise<never>((_, reject) => {
        timer = setTimeout(() => {
          ac.abort();
          reject(new Error(`Provider timed out after ${this.cfg.providerTimeoutMs}ms`));
        }, this.cfg.providerTimeoutMs);
      });
      const result = await Promise.race([
        provider.fetchJobs({ http: this.http, config: this.cfg, signal: ac.signal, prefilter: this.matcher.titlePrefilter }),
        timeout,
      ]);
      return { ok: true, provider, result, ms: Date.now() - started };
    } catch (err) {
      const msg = redact(err instanceof Error ? err.message : 'Unknown provider error');
      logger.warn(`Provider ${provider.id} failed`, { error: msg });
      return { ok: false, provider, error: msg.slice(0, 300), ms: Date.now() - started };
    } finally {
      if (timer) clearTimeout(timer);
      parent.removeEventListener('abort', onParentAbort);
    }
  }

  private async processProvider(f: Fetched, seen: Set<string>, dryRun: boolean, summary: SyncSummary): Promise<ProviderRunReport> {
    const report: ProviderRunReport = {
      provider: f.provider.id,
      status: 'FAILED',
      fullyCovered: false,
      durationMs: f.ms,
      discovered: 0,
      inserted: 0,
      updated: 0,
      deduplicated: 0,
      rejected: 0,
      skipped: 0,
      errors: [],
    };
    if (!f.ok) {
      report.errors.push(f.error);
      return report;
    }

    const { jobs, boardsFailed, errors } = f.result;
    report.errors.push(...errors.slice(0, 5).map((e) => redact(e)));
    report.status = boardsFailed > 0 ? 'PARTIAL' : 'SUCCESS';
    report.fullyCovered = boardsFailed === 0;
    report.discovered = jobs.length;
    summary.jobsDiscovered += jobs.length;

    const reject = (reason: string) => {
      report.rejected++;
      summary.jobsRejected++;
      summary.rejectionReasons[reason] = (summary.rejectionReasons[reason] ?? 0) + 1;
    };

    for (const raw of jobs) {
      // Providers hand us untrusted data: one malformed posting must never abort the batch.
      try {
        const norm = normalizeJob({ ...raw, source: f.provider.source }, this.cfg.maxDescriptionChars);
        if (!norm.ok) {
          reject(norm.reason);
          continue;
        }
        const job = norm.job;

        const keys = [`ext:${job.source}:${job.externalId}`, `url:${job.canonicalUrl}`, job.dedupeKey ? `key:${job.dedupeKey}` : null];
        if (keys.some((k) => k !== null && seen.has(k))) {
          report.deduplicated++;
          summary.jobsDeduplicated++;
          continue;
        }

        const match = this.matcher.evaluate(job);
        if (!match.accepted) {
          reject(match.rejection ?? 'rejected');
          continue;
        }
        keys.forEach((k) => k !== null && seen.add(k));
        summary.jobsAccepted++;
        if (dryRun) continue;

        const outcome = await this.repo.upsert(job, match);
        if (outcome === 'inserted') {
          report.inserted++;
          summary.jobsInserted++;
        } else if (outcome === 'updated') {
          report.updated++;
          report.deduplicated++;
          summary.jobsUpdated++;
          summary.jobsDeduplicated++;
        } else {
          report.deduplicated++;
          summary.jobsDeduplicated++;
        }
      } catch (err) {
        report.skipped++;
        summary.jobsSkipped++;
        if (report.errors.length < 5) report.errors.push(`persist: ${redact(err instanceof Error ? err.message : 'error').slice(0, 120)}`);
      }
    }
    // If any write failed, last_seen_at was not refreshed for that job, so don't let freshness act on this source.
    if (report.skipped > 0) report.fullyCovered = false;
    return report;
  }
}
