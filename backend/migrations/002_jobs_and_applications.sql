-- 002_jobs_and_applications.sql

-- Jobs Table
CREATE TABLE IF NOT EXISTS jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    external_id TEXT NULL,
    title TEXT NOT NULL,
    company TEXT NOT NULL,
    location TEXT NULL,
    salary TEXT NULL,
    employment_type TEXT NULL,
    experience_requirement TEXT NULL,
    url TEXT NULL,
    source TEXT NULL,
    description TEXT NULL,
    skills JSONB NOT NULL DEFAULT '[]'::jsonb,
    posted_date TIMESTAMPTZ NULL,
    discovered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    match_score NUMERIC NULL,
    match_reason TEXT NULL,
    is_saved BOOLEAN NOT NULL DEFAULT FALSE,
    notes TEXT NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    raw_data JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Unique constraints / Indexes for Job Deduplication:
-- 1. Deduplication by source + external_id (when external_id is present)
CREATE UNIQUE INDEX IF NOT EXISTS uq_jobs_source_external_id 
    ON jobs (source, external_id) 
    WHERE external_id IS NOT NULL AND external_id <> '';

-- 2. Deduplication by source + url (when url is present)
CREATE UNIQUE INDEX IF NOT EXISTS uq_jobs_source_url 
    ON jobs (source, url) 
    WHERE url IS NOT NULL AND url <> '';

-- Query indexes
CREATE INDEX IF NOT EXISTS idx_jobs_company ON jobs (company);
CREATE INDEX IF NOT EXISTS idx_jobs_source ON jobs (source);
CREATE INDEX IF NOT EXISTS idx_jobs_is_saved ON jobs (is_saved);
CREATE INDEX IF NOT EXISTS idx_jobs_posted_date ON jobs (posted_date DESC);
CREATE INDEX IF NOT EXISTS idx_jobs_discovered_at ON jobs (discovered_at DESC);

-- Job Applications Table
CREATE TABLE IF NOT EXISTS job_applications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID NULL REFERENCES jobs(id) ON DELETE SET NULL,
    company TEXT NOT NULL,
    role TEXT NOT NULL,
    salary TEXT NULL,
    location TEXT NULL,
    url TEXT NULL,
    status TEXT NOT NULL DEFAULT 'applied',
    applied_at TIMESTAMPTZ NULL,
    follow_up_date TIMESTAMPTZ NULL,
    interview_date TIMESTAMPTZ NULL,
    interview_stage TEXT NULL,
    recruiter_name TEXT NULL,
    recruiter_contact TEXT NULL,
    resume_id TEXT NULL,
    resume_used TEXT NULL,
    cover_letter_reference TEXT NULL,
    next_action TEXT NULL,
    notes TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_applications_job_id ON job_applications (job_id);
CREATE INDEX IF NOT EXISTS idx_applications_status ON job_applications (status);
CREATE INDEX IF NOT EXISTS idx_applications_applied_at ON job_applications (applied_at DESC);
CREATE INDEX IF NOT EXISTS idx_applications_follow_up_date ON job_applications (follow_up_date) WHERE follow_up_date IS NOT NULL;

-- Saved Searches Table
CREATE TABLE IF NOT EXISTS saved_searches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    keywords TEXT NULL,
    job_title TEXT NULL,
    company TEXT NULL,
    location TEXT NULL,
    remote_preference TEXT NULL,
    employment_type TEXT NULL,
    experience TEXT NULL,
    salary TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
