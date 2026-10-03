# Career OS Backend

High-performance PostgreSQL backend API and automated daily JSON ingestion engine for Career OS.

## Tech Stack
* **Runtime**: Node.js (TypeScript)
* **Framework**: Express.js
* **Database**: PostgreSQL 17 (pg driver with connection pool)
* **Validation**: Zod schema validation
* **Testing**: Jest + Supertest
* **Process Management**: tsx / compiled JS

---

## Architecture

```text
Daily Research Automation
          │
          ▼
      jobs.json
    freelance.json
          │
          ▼
  Import CLI / Script (import-daily-data.ts)
          │
          ▼
   POST /api/v1/import/* (Protected via IMPORT_API_KEY)
          │
          ▼
   Zod Schema Validation & Input Normalization
          │
          ▼
   Idempotent Deduplication & Transactional Upsert
          │
          ▼
      PostgreSQL (Tables: jobs, freelance_leads, import_runs)
          │
          ▼
   REST API (/api/v1/jobs, /api/v1/freelance/*, etc.)
          │
          ▼
   Career OS Flutter App (Riverpod + ApiClient)
```

---

## Environment Variables

Copy `.env.example` to `.env` in the `backend/` directory:

```bash
cp .env.example .env
```

| Variable | Description | Example / Default |
| :--- | :--- | :--- |
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://postgres:postgres@localhost:5432/career_os` |
| `PORT` | HTTP server port | `8080` |
| `IMPORT_API_KEY` | Bearer token for server-to-server import API | `your_secure_import_key` |
| `JWT_SECRET` | Secret for user sessions | `your_secure_jwt_secret` |
| `CORS_ORIGINS` | Allowed CORS origins | `*` |
| `NODE_ENV` | Application environment | `development` / `production` / `test` |

> **Security Note**: Never commit `.env` containing real credentials. `.env` is ignored by Git.

---

## Setup & Running

### 1. Install Dependencies
```bash
npm install
```

### 2. Run Database Migrations
Applies all SQL migrations from `migrations/` transactionally:
```bash
npm run migrate
```

### 3. Start Development Server
```bash
npm run dev
```

### 4. Build and Start Production Server
```bash
npm run build
npm run start
```

---

## Daily JSON Ingestion

### Import Jobs
```bash
npm run import:jobs -- ./fixtures/jobs.example.json
```

### Import Freelance Projects
```bash
npm run import:freelance -- ./fixtures/freelance.example.json
```

### Ingestion Features:
1. **Deduplication**:
   - Jobs: `source + external_id`, `source + normalized(url)`, or `company + normalized(title)`.
   - Freelance: `platform + external_id`, `platform + normalized(url)`, or `client_name + normalized(title)`.
2. **User Field Preservation**:
   - Source fields (salary, skills, descriptions, match score) are updated.
   - User-managed fields (`is_saved`, `notes`, `status`, `proposal`, `follow_up_date`) are **never** overwritten by daily research batches.
3. **Audit Trail**: Every batch is recorded in `import_runs` with counts (`received`, `inserted`, `updated`, `duplicates`, `rejected`).

---

## SQLite to PostgreSQL Migration

To migrate existing local SQLite data to PostgreSQL:

```bash
npm run migrate:sqlite -- <path-to-sqlite-file>
```

Output:
```text
Migration Summary:
---------------------------------
Users migrated: X
Jobs migrated: X
Applications migrated: X
Freelance leads migrated: X
Clients migrated: X
Projects migrated: X
Payments migrated: X
Errors: 0
---------------------------------
```

---

## Running Tests

Runs the automated test suite verifying all CRUD endpoints, authentication, deduplication, and security:

```bash
npm test
```

---

## Hourly live-job sync

The backend discovers, filters, scores and deduplicates live jobs from Greenhouse, Lever, Ashby,
RemoteOK and WeWorkRemotely, and the Flutter app reads them from `GET /api/v1/jobs`.

```bash
npm run migrate        # applies 005_job_sync.sql
npm run jobs:setup     # idempotent: .env, local JOB_SYNC_SECRET, schema checks
npm run jobs:verify    # end-to-end self check (-- --live also dry-runs real providers)
npm run jobs:sync      # run a sync now (-- --dry-run to write nothing)
```

Production trigger: `POST /api/v1/internal/jobs/sync` with `Authorization: Bearer <JOB_SYNC_SECRET>`,
called hourly by `.github/workflows/hourly-job-sync.yml`. Full guide: [docs/HOURLY_JOB_SYNC.md](../docs/HOURLY_JOB_SYNC.md).
