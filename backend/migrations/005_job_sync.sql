-- 005_job_sync.sql
-- Hourly live-job sync: freshness tracking, stronger dedupe keys, and a lease lock.
-- Additive and idempotent. Existing rows are preserved; nothing is deleted.

-- 1. Freshness + dedupe columns on the existing jobs table
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS canonical_url TEXT NULL;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS dedupe_key TEXT NULL;      -- normalized company|title|location
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS content_hash TEXT NULL;    -- sha256 fingerprint of company+description
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS last_seen_at TIMESTAMPTZ NULL;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'OPEN';

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_jobs_status') THEN
        ALTER TABLE jobs ADD CONSTRAINT chk_jobs_status
            CHECK (status IN ('OPEN', 'CLOSED', 'STALE', 'UNKNOWN'));
    END IF;
END $$;

-- 2. Backfill keys for existing rows. Only the oldest row per key receives the key, so the
--    unique indexes below can always be created even if the table already holds duplicates.
UPDATE jobs SET last_seen_at = COALESCE(last_seen_at, discovered_at);

WITH ranked AS (
    SELECT id,
           row_number() OVER (PARTITION BY url ORDER BY created_at, id) AS rn
    FROM jobs
    WHERE canonical_url IS NULL AND url IS NOT NULL AND url <> ''
)
UPDATE jobs j SET canonical_url = j.url FROM ranked r WHERE j.id = r.id AND r.rn = 1;

WITH keyed AS (
    SELECT id,
           btrim(regexp_replace(lower(company), '[^a-z0-9]+', ' ', 'g')) || '|' ||
           btrim(regexp_replace(lower(title), '[^a-z0-9]+', ' ', 'g')) || '|' ||
           btrim(regexp_replace(lower(COALESCE(location, '')), '[^a-z0-9]+', ' ', 'g')) AS k,
           btrim(regexp_replace(lower(title), '[^a-z0-9]+', ' ', 'g')) AS t,
           btrim(regexp_replace(lower(company), '[^a-z0-9]+', ' ', 'g')) AS c,
           created_at
    FROM jobs
    WHERE dedupe_key IS NULL
), ranked AS (
    SELECT id, k, row_number() OVER (PARTITION BY k ORDER BY created_at, id) AS rn
    FROM keyed WHERE t <> '' AND c <> ''
)
UPDATE jobs j SET dedupe_key = r.k FROM ranked r WHERE j.id = r.id AND r.rn = 1
    AND NOT EXISTS (SELECT 1 FROM jobs x WHERE x.dedupe_key = r.k);

-- 3. Constraints / indexes (partial unique: NULL keys never conflict)
CREATE UNIQUE INDEX IF NOT EXISTS uq_jobs_canonical_url ON jobs (canonical_url) WHERE canonical_url IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_jobs_dedupe_key ON jobs (dedupe_key) WHERE dedupe_key IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_jobs_content_hash ON jobs (content_hash) WHERE content_hash IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs (status);
CREATE INDEX IF NOT EXISTS idx_jobs_last_seen_at ON jobs (last_seen_at);
CREATE INDEX IF NOT EXISTS idx_jobs_match_score ON jobs (match_score DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_jobs_status_source_seen ON jobs (status, source, last_seen_at);

-- 4. Lease-based sync lock. Works through pooled connections (e.g. Neon's PgBouncer), where
--    session-level advisory locks are unreliable, and self-heals after a crash via expiry.
CREATE TABLE IF NOT EXISTS job_sync_locks (
    name TEXT PRIMARY KEY,
    owner TEXT NOT NULL,
    locked_until TIMESTAMPTZ NOT NULL,
    acquired_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Sync runs reuse import_runs (data_type = 'jobs_sync'); per-provider detail lives in metadata.
CREATE INDEX IF NOT EXISTS idx_import_runs_type_created ON import_runs (data_type, created_at DESC);

-- DOWN (manual, not executed by the runner):
--   DROP TABLE IF EXISTS job_sync_locks;
--   DROP INDEX IF EXISTS uq_jobs_canonical_url, uq_jobs_dedupe_key, idx_jobs_content_hash, idx_jobs_status,
--     idx_jobs_last_seen_at, idx_jobs_match_score, idx_jobs_status_source_seen, idx_import_runs_type_created;
--   ALTER TABLE jobs DROP CONSTRAINT IF EXISTS chk_jobs_status;
--   ALTER TABLE jobs DROP COLUMN IF EXISTS canonical_url, DROP COLUMN IF EXISTS dedupe_key,
--     DROP COLUMN IF EXISTS content_hash, DROP COLUMN IF EXISTS last_seen_at, DROP COLUMN IF EXISTS status;
