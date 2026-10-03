# Hourly live-job sync

The Node backend (`backend/`) discovers live jobs every hour, filters and scores them against the
candidate profile, deduplicates them into PostgreSQL, and serves them to the Flutter app.
Flutter no longer scrapes job boards itself; it reads `GET /api/v1/jobs` and caches locally.

Legend used below: **AUTOMATED** = runs with no human involvement. **ONE-TIME MANUAL** = needs your
account or credentials and cannot be done from the repo.

## 1. Architecture and data flow

```
GitHub Actions cron (hourly)            AUTOMATED   .github/workflows/hourly-job-sync.yml
   │  POST /api/v1/internal/jobs/sync   Authorization: Bearer <JOB_SYNC_SECRET>
   ▼
JobSyncService.run()  ◄── also called by `npm run jobs:sync` (same code path)
   │  acquire DB lease lock  (second concurrent sync exits with 409)
   │  providers fetch concurrently, each isolated, with timeout + retry
   ▼
normalize → validate → dedupe-in-run → match/score → persist (race-safe upsert) → freshness
   ▼
PostgreSQL / Neon  (jobs, import_runs, job_sync_locks)
   ▼
GET /api/v1/jobs?page=&limit=&status=&min_score=...   (default sort: match_score DESC, posted_date DESC)
   ▼
Flutter: CareerRepository.refreshJobsFromBackend() → Drift cache (offline, fast first paint)
```

Code lives in `backend/src/modules/job-sync/`:

| File | Responsibility |
|---|---|
| `job-sync.service.ts` | The single orchestrator (lock, providers, counters, run record, freshness) |
| `providers/*.provider.ts` | Greenhouse, Lever, Ashby, RemoteOK, WeWorkRemotely adapters (public APIs/feeds only) |
| `http.ts` | Hardened fetch: timeout, retry/backoff, host allowlist, size cap, safe errors |
| `job-normalization.service.ts` | Text sanitising, URL canonicalisation, dedupe keys, validation |
| `job-matching.service.ts` | Hard filters + 0-100 relevance score + human-readable reason |
| `job-sync.repository.ts` | Dedupe lookup, `INSERT … ON CONFLICT DO NOTHING`, freshness SQL, lease lock, run records |
| `job-sync.config.ts` | Every tunable: boards, candidate profile, thresholds, timeouts |
| `job-sync.controller.ts` | `POST /internal/jobs/sync`, `GET /internal/jobs/sync/status` |

## 2. Providers

All five are official public endpoints; no HTML scraping, no API keys.

| Provider | Endpoint | Notes |
|---|---|---|
| Greenhouse | `boards-api.greenhouse.io/v1/boards/{board}/jobs?content=true` | 12 boards by default |
| Lever | `api.lever.co/v0/postings/{org}?mode=json&limit=200` | 3 orgs |
| Ashby | `api.ashbyhq.com/posting-api/job-board/{org}` | 5 orgs; unlisted postings skipped |
| RemoteOK | `remoteok.com/api` | links back to RemoteOK as their terms require |
| WeWorkRemotely | `weworkremotely.com/categories/remote-programming-jobs.rss` | `<region>` is used for location filtering |

Board lists are the ones the Flutter provider had verified live. Change them with
`JOB_SYNC_GREENHOUSE_BOARDS`, `JOB_SYNC_LEVER_ORGS`, `JOB_SYNC_ASHBY_ORGS` (slugs must match
`^[a-z0-9][a-z0-9_-]{0,63}$`). A board that 404s is reported in the run record and skipped; it
never fails the other boards. If **every** board of a provider fails, that provider is `FAILED`.

Behaviour per request: 15 s timeout, up to 3 retries with exponential backoff + jitter (500 ms →
8 s cap, `Retry-After` honoured up to the cap) for timeouts, network errors, 408/425/429/5xx
only. 400/401/403/404 and malformed bodies are never retried. Each provider also has a 120 s
overall budget. Only five fixed hostnames can ever be contacted (SSRF guard), redirects are
re-validated, and responses over 20 MB are dropped.

## 3. Matching (what gets stored)

The backend has no resume, so the candidate profile lives in `DEFAULT_PROFILE`
(`job-sync.config.ts`): target roles, skills with primary/secondary tiers, max years, locations.
Override it without code changes via `JOB_SYNC_PROFILE_PATH` (JSON, partial) and the env vars in
section 8.

Hard rejects (not stored): seniority titles (senior/staff/principal/lead/manager/architect, level
III+), internships, unrelated professions or stacks (sales, HR, data science, iOS/Android, QA…),
titles that match no target role, stated experience above `JOB_SYNC_MAX_YEARS` (default 2),
region-locked remote roles (US/EU/… only) and on-site roles outside India, postings older than 365
days, malformed/unsafe records.

Score (0-100) = 40% role + 30% skills + 15% experience + 15% location; accepted at
`JOB_SYNC_MIN_MATCH_SCORE` (default 45). Stored in `match_score` / `match_reason`, e.g.
`Role: Backend / Java / Spring · Skills: Java, PostgreSQL · Experience: 0-2 years · Location: Bengaluru, India`.

The Flutter app still re-scores locally per resume (`JobScoringService`); a refresh never
overwrites that local score, the saved flag or notes.

## 4. Deduplication

First hit wins, checked in order; enforced by unique indexes so concurrent writers cannot
duplicate (`INSERT … ON CONFLICT DO NOTHING`, then re-lookup):

1. `source + external_id` (`uq_jobs_source_external_id`)
2. canonical URL (`uq_jobs_canonical_url`): https, no `www`, no tracking params/fragment/trailing slash, sorted query; `gh_jid` is kept because it identifies the job
3. normalized company + title + location (`uq_jobs_dedupe_key`), with Bangalore = Bengaluru and Inc/Ltd stripped
4. content fingerprint (`content_hash`): same company + same description (≥200 chars) **and** same title or same location. Deliberately conservative so one JD shared across cities is not collapsed.

Only the provider that owns a row rewrites it; cross-posts from other sources are no-ops.

## 5. Freshness

`jobs.status` ∈ `OPEN | STALE | CLOSED | UNKNOWN`, `last_seen_at` refreshed every time a provider
still returns the job. Not seen for 48 h → `STALE`; for 14 days → `CLOSED`
(`JOB_SYNC_STALE_AFTER_HOURS`, `JOB_SYNC_CLOSE_AFTER_DAYS`). A job that reappears becomes `OPEN`.
Rows are never deleted. Freshness only runs for providers that fetched **fully** that run, so an
outage cannot close jobs. Manual/imported jobs (no `last_seen_at`) are never touched.
`GET /api/v1/jobs` returns `OPEN` by default; `status=ALL|STALE|CLOSED` to see others.

## 6. Security

* `POST /api/v1/internal/jobs/sync` and `GET …/status` require `Authorization: Bearer <JOB_SYNC_SECRET>`, compared in constant time. Unset or < 24 chars → **503, endpoints disabled** (fails closed, no default). 20 failed attempts per 15 min per client → 429.
* The secret is never logged or stored: a redacting logger masks it, bearer tokens and DB credentials; provider error text is redacted before it reaches logs, API responses or `import_runs`. Tests assert this.
* Provider data is untrusted: zod-validated, HTML/script stripped to plain text, control chars removed, lengths capped, dates sanity-checked, SQL fully parameterised.
* `raw_data` is never returned by the jobs API.
* Not part of this change (pre-existing): the other `/api/v1/*` CRUD routes, including `GET /jobs`, have no user authentication. Treat the backend URL as semi-private or add auth before sharing it.

## 7. Sync-run tracking

Each run is a row in `import_runs` (`data_type = 'jobs_sync'`): start/finish, status
(`SUCCESS`, `PARTIAL_SUCCESS`, `FAILED`), counts (discovered / inserted / updated / deduplicated /
rejected) and in `metadata`: providers attempted/succeeded/failed, skipped, per-provider detail,
rejection reasons, stale/closed counts. A run killed mid-way is marked `FAILED` by the next run.
Skipped (locked) calls leave no row.

## 8. Environment variables

Only `JOB_SYNC_SECRET` is required. Everything else has a default (see `backend/.env.example`).

| Variable | Default | Meaning |
|---|---|---|
| `JOB_SYNC_SECRET` | none | Bearer secret, ≥ 24 chars |
| `JOB_SYNC_PROVIDERS` | all five | Comma list to enable |
| `JOB_SYNC_GREENHOUSE_BOARDS` / `_LEVER_ORGS` / `_ASHBY_ORGS` | see example | ATS slugs |
| `JOB_SYNC_MIN_MATCH_SCORE` | 45 | Acceptance threshold |
| `JOB_SYNC_MAX_YEARS` | 2 | Max minimum-years requirement |
| `JOB_SYNC_ALLOW_INTERNSHIPS` | false | |
| `JOB_SYNC_MAX_POSTED_AGE_DAYS` | 365 | Ignore older postings |
| `JOB_SYNC_STALE_AFTER_HOURS` / `_CLOSE_AFTER_DAYS` | 48 / 14 | Freshness |
| `JOB_SYNC_TIMEOUT_MS` / `_MAX_RETRIES` / `_PROVIDER_TIMEOUT_MS` | 15000 / 3 / 120000 | Network limits |
| `JOB_SYNC_LOCK_TTL_SECONDS` | 900 | Lease length (sync aborts 30 s before it ends) |
| `JOB_SYNC_PROFILE_PATH` | none | JSON profile override |

Flutter reads the backend URL from `--dart-define=API_BASE_URL=https://…` at build time
(falls back to localhost / the Android emulator address). Flutter never sees `JOB_SYNC_SECRET`.

## 9. Local testing

```bash
cd backend
npm install
npm run migrate          # applies 005_job_sync.sql (idempotent)
npm run jobs:setup       # creates .env if missing, generates a local JOB_SYNC_SECRET, checks schema
npm run jobs:verify      # self-check (add -- --live to also dry-run the real providers)
npm run jobs:sync -- --dry-run   # fetch + filter, write nothing
npm run jobs:sync        # real sync into your local DB
npm test                 # needs the local Postgres from DATABASE_URL
npm run typecheck && npm run build
```

Tests use `source LIKE 'TestSync%'` rows and clean up after themselves, but the legacy
`api.test.ts` deletes **all** rows from the jobs/applications tables of whatever `DATABASE_URL`
points at. Use a throw-away database for `npm test`, never production.

## 10. Production deployment

1. **ONE-TIME MANUAL** Deploy `backend/` wherever you host it (this repo contains no host config) with
   `DATABASE_URL`, `JWT_SECRET`, `IMPORT_API_KEY`, `JOB_SYNC_SECRET` set. Build `npm run build`, start `npm start`.
2. **AUTOMATED** Run `npm run migrate` as part of the release (creates columns, indexes, lock table).
3. **ONE-TIME MANUAL** Add GitHub repository secrets `BACKEND_URL` and `JOB_SYNC_SECRET` (below).
4. **ONE-TIME MANUAL** Build the app with `--dart-define=API_BASE_URL=<your backend URL>`.

Neon: use the pooled or direct connection string, either works; the lock is a table lease, not a
session advisory lock, so PgBouncer transaction pooling is fine.

## 11. Scheduler

`.github/workflows/hourly-job-sync.yml` runs at minute 17 of every hour (and on demand via
*Run workflow*). It checks its secrets, wakes the backend (`/health`, with retries, for cold
starts), calls the sync endpoint with the secret passed through curl's stdin config (never in
argv), prints only counters, and fails the run on any HTTP code except 200/202/409
(409 = another sync was running, which is fine).

One-time setup (the secret must exist on both sides):

```bash
# 1. generate (already done locally by `npm run jobs:setup`); for production generate a new one:
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
# 2. set it on your host as JOB_SYNC_SECRET, then store the same value in GitHub:
gh secret set JOB_SYNC_SECRET          # paste the value
gh secret set BACKEND_URL              # e.g. https://your-backend.example.com
```

Caveats of GitHub cron: runs can be delayed by several minutes under load, and GitHub disables
scheduled workflows after 60 days without repository activity (re-enable in the Actions tab, or
push any commit). If you later move to a host with native cron (Render cron, Railway, Fly
machines, Cloud Scheduler…) point it at the same `POST` instead and delete the workflow.

## 12. Manual trigger

```bash
curl -X POST "$BACKEND_URL/api/v1/internal/jobs/sync" -H "Authorization: Bearer $JOB_SYNC_SECRET"
# options (JSON body): {"dryRun": true, "providers": ["lever","ashby"]}   query: ?wait=false → 202 immediately
```

Or `npm run jobs:sync` locally, or *Run workflow* in the GitHub Actions tab.

## 13. Verifying hourly execution

* GitHub → Actions → "Hourly job sync": one green run per hour; the run summary lists counters.
* `GET /api/v1/internal/jobs/sync/status` (with the secret) → `lastSuccessfulSync` should be < 1 h old; `healthy` turns false after 3 h without a success.
* `SELECT started_at, status, inserted_count, updated_count FROM import_runs WHERE data_type='jobs_sync' ORDER BY started_at DESC LIMIT 5;`
* Failed providers don't break a run: look for `PARTIAL_SUCCESS` and the per-provider `errors` in `metadata.providers`.

## 14. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| 503 `SYNC_NOT_CONFIGURED` | `JOB_SYNC_SECRET` unset or shorter than 24 chars on the server |
| 401 | Secret in GitHub ≠ secret on the server |
| 429 | Too many bad attempts from one address; wait 15 min |
| 409 `SYNC_IN_PROGRESS` | Another run holds the lease (expires on its own after 15 min if a process died) |
| 502 / status `FAILED` | Every provider failed: check outbound network from the server and `errorSummary` |
| `PARTIAL_SUCCESS` | Some provider/board failed; usually a board slug that no longer exists: edit the board env var |
| Very few jobs | Expected: ~300 fetched, ~10 kept. Loosen with `JOB_SYNC_MIN_MATCH_SCORE`, `JOB_SYNC_MAX_YEARS`, or add boards |
| Workflow stopped running | Scheduled workflows pause after 60 idle days; re-enable in Actions |
| App shows no jobs | Built without `API_BASE_URL`, or backend has no jobs yet (run a sync) |

Known limitation: jobs the backend later marks `STALE`/`CLOSED` are not removed from the phone's
local cache (the Drift schema has no status column); they simply stop being refreshed.
