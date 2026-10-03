import type { HttpClient } from './http';
import type { JobSyncConfig } from './job-sync.config';

export type JobStatus = 'OPEN' | 'CLOSED' | 'STALE' | 'UNKNOWN';

/** A posting exactly as a provider adapter extracted it (untrusted, not yet validated). */
export interface RawJob {
  source: string;
  externalId: string;
  url: string;
  title: string;
  company: string;
  location?: string | null;
  description?: string | null;
  postedAt?: Date | string | number | null;
  salary?: string | null;
  employmentType?: string | null;
  skills?: string[];
  isRemote?: boolean;
  metadata?: Record<string, unknown>;
}

/** A posting after normalization + validation; safe to persist. */
export interface NormalizedJob {
  source: string;
  externalId: string;
  url: string;
  canonicalUrl: string;
  title: string;
  company: string;
  location: string | null;
  description: string | null;
  postedAt: Date | null;
  salary: string | null;
  employmentType: string | null;
  skills: string[];
  isRemote: boolean;
  dedupeKey: string | null;
  contentHash: string;
  metadata: Record<string, unknown>;
}

export interface MatchResult {
  accepted: boolean;
  score: number;
  reason: string;
  /** Machine-readable rejection bucket, set when accepted is false. */
  rejection?: string;
  matchedSkills: string[];
  experienceRequirement: string | null;
}

export interface ProviderFetchResult {
  jobs: RawJob[];
  boardsAttempted: number;
  boardsFailed: number;
  errors: string[];
}

export interface ProviderContext {
  http: HttpClient;
  config: JobSyncConfig;
  signal?: AbortSignal;
  /** Cheap title/location check applied before per-board caps so irrelevant postings never crowd out relevant ones. */
  prefilter?: (title: string, location: string | null) => boolean;
}

export interface JobProvider {
  /** Stable id used in JOB_SYNC_PROVIDERS and run metadata. */
  readonly id: string;
  /** Value stored in jobs.source. */
  readonly source: string;
  /** Throws only when nothing at all could be fetched. Partial failures go in `errors`. */
  fetchJobs(ctx: ProviderContext): Promise<ProviderFetchResult>;
}

export type ProviderRunStatus = 'SUCCESS' | 'PARTIAL' | 'FAILED';

export interface ProviderRunReport {
  provider: string;
  status: ProviderRunStatus;
  fullyCovered: boolean;
  durationMs: number;
  discovered: number;
  inserted: number;
  updated: number;
  deduplicated: number;
  rejected: number;
  skipped: number;
  errors: string[];
}

export type SyncStatus = 'IN_PROGRESS' | 'SUCCESS' | 'PARTIAL_SUCCESS' | 'FAILED' | 'SKIPPED_LOCKED';

export interface SyncSummary {
  runId: string | null;
  status: SyncStatus;
  startedAt: string;
  completedAt: string | null;
  dryRun: boolean;
  providersAttempted: number;
  providersSucceeded: number;
  providersFailed: number;
  jobsDiscovered: number;
  /** Passed filters and dedupe-in-run (in dry runs nothing is written). */
  jobsAccepted: number;
  jobsInserted: number;
  jobsUpdated: number;
  jobsSkipped: number;
  jobsDeduplicated: number;
  jobsRejected: number;
  jobsMarkedStale: number;
  jobsMarkedClosed: number;
  rejectionReasons: Record<string, number>;
  providers: ProviderRunReport[];
  errorSummary: string | null;
}
