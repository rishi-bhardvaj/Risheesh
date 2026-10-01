-- 003_freelance_and_clients.sql

-- Clients Table
CREATE TABLE IF NOT EXISTS clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    contact_name TEXT NULL,
    email TEXT NULL,
    phone TEXT NULL,
    platform TEXT NULL,
    location TEXT NULL,
    status TEXT NOT NULL DEFAULT 'PROSPECT',
    notes TEXT NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_clients_name ON clients (name);
CREATE INDEX IF NOT EXISTS idx_clients_status ON clients (status);

-- Freelance Leads Table
CREATE TABLE IF NOT EXISTS freelance_leads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    external_id TEXT NULL,
    client_id UUID NULL REFERENCES clients(id) ON DELETE SET NULL,
    project_id UUID NULL, -- Linked later if project created
    title TEXT NOT NULL,
    client_name TEXT NULL,
    contact_name TEXT NULL,
    contact_info TEXT NULL,
    platform TEXT NULL,
    description TEXT NULL,
    skills JSONB NOT NULL DEFAULT '[]'::jsonb,
    budget NUMERIC NULL,
    currency TEXT NOT NULL DEFAULT 'USD',
    url TEXT NULL,
    status TEXT NOT NULL DEFAULT 'NEW_LEAD',
    proposal TEXT NULL,
    deadline TIMESTAMPTZ NULL,
    follow_up_date TIMESTAMPTZ NULL,
    follow_up_note TEXT NULL,
    next_action TEXT NULL,
    notes TEXT NULL,
    lead_date TIMESTAMPTZ NULL,
    match_score NUMERIC NULL,
    match_reason TEXT NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    raw_data JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Deduplication indexes for Freelance Leads:
-- 1. Deduplication by platform + external_id
CREATE UNIQUE INDEX IF NOT EXISTS uq_freelance_leads_platform_external_id 
    ON freelance_leads (platform, external_id) 
    WHERE external_id IS NOT NULL AND external_id <> '';

-- 2. Deduplication by platform + url
CREATE UNIQUE INDEX IF NOT EXISTS uq_freelance_leads_platform_url 
    ON freelance_leads (platform, url) 
    WHERE url IS NOT NULL AND url <> '';

CREATE INDEX IF NOT EXISTS idx_freelance_leads_platform ON freelance_leads (platform);
CREATE INDEX IF NOT EXISTS idx_freelance_leads_status ON freelance_leads (status);
CREATE INDEX IF NOT EXISTS idx_freelance_leads_created_at ON freelance_leads (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_freelance_leads_client_id ON freelance_leads (client_id);
CREATE INDEX IF NOT EXISTS idx_freelance_leads_follow_up_date ON freelance_leads (follow_up_date) WHERE follow_up_date IS NOT NULL;

-- Projects Table
CREATE TABLE IF NOT EXISTS projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT NULL,
    status TEXT NOT NULL DEFAULT 'in_progress',
    progress NUMERIC NOT NULL DEFAULT 0.0,
    tech_stack TEXT NULL,
    github_url TEXT NULL,
    live_url TEXT NULL,
    deadline TIMESTAMPTZ NULL,
    notes TEXT NULL,
    client_id UUID NULL REFERENCES clients(id) ON DELETE SET NULL,
    lead_id UUID NULL REFERENCES freelance_leads(id) ON DELETE SET NULL,
    is_freelance BOOLEAN NOT NULL DEFAULT FALSE,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_projects_client_id ON projects (client_id);
CREATE INDEX IF NOT EXISTS idx_projects_lead_id ON projects (lead_id);
CREATE INDEX IF NOT EXISTS idx_projects_status ON projects (status);
CREATE INDEX IF NOT EXISTS idx_projects_is_freelance ON projects (is_freelance);

-- Freelance Payments Table
CREATE TABLE IF NOT EXISTS freelance_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    project_id UUID NULL REFERENCES projects(id) ON DELETE SET NULL,
    amount NUMERIC NOT NULL,
    currency TEXT NOT NULL DEFAULT 'USD',
    payment_date TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL DEFAULT 'EXPECTED',
    description TEXT NULL,
    notes TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payments_client_id ON freelance_payments (client_id);
CREATE INDEX IF NOT EXISTS idx_payments_project_id ON freelance_payments (project_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON freelance_payments (status);
