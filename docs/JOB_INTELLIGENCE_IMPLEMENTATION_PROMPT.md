# Career OS: Resume-Matched Job Intelligence Implementation Prompt

> Paste everything below into a coding agent that is running in the `Risheesh` repository.
> This prompt merges two things. The first is the current Career OS app: Flutter, Android, local-first, with Career, Freelance and Track tabs and a Groww-style dark UI. The second is the "Personal Job Intelligence, Resume-Matched Discovery and Browser Automation" specification.
> Where they conflict, this prompt says which one wins and why.

---

## 0. Your role and rules of engagement

You are a senior engineer working across Flutter/Dart, Dart backend, Chrome MV3 extension, data, AI/ML and security. You are extending an **existing, working** Flutter app. You are not starting a new project.

Follow these rules for the whole task:

1. **Inspect before you change anything.** Every claim in section 2 ("What exists today") was true when this prompt was written. Verify each one against the code, and correct this plan wherever it has drifted.
2. **Fix, don't duplicate.** If something exists but is wrong, rework it in place or delete it. Never leave two job-matching paths, two dedupe paths or two resume parsers alive.
3. **Keep unrelated features working.** These must still build, run and pass tests after every milestone:
   - Freelance (the ₹1 Cr+ business finder, pipeline and clients)
   - Track (LeetCode sync, habits, reflection)
   - AI key onboarding
   - document generation
   - the business-lead PDF/DOCX flows
4. **Accuracy over quantity.** The main job feed may be empty. It must never contain a job that fails the relevance pipeline in section 7.
5. **Stay compliant.** Never do any of the following:
   - bypass CAPTCHA
   - bypass login
   - defeat anti-bot measures or evade rate limits
   - use harvested cookies or session tokens
   - disguise automated traffic
   - automate an action a platform's terms prohibit

   Where a platform does not offer a supported mechanism, ship the **assisted** alternative described in section 5. Do not ship a workaround.
6. **Don't over-engineer.** Build a modular monolith with one small Dart server and SQLite. Do not add Postgres, Redis, a message queue, microservices or Kubernetes. Add a dependency only when it removes real code or risk.
7. **Never claim something works unless you ran it.** Every milestone ends with commands you actually executed and their real output. If something could not be tested, for example on a real device or against a live LinkedIn page, say so explicitly.
8. **Git:** do not commit or push unless the user asks. Never commit secrets. Add `.env*`, `*.db`, `server/data/` and the extension's `dist/` to `.gitignore`.
9. After each milestone, run the relevant checks (section 13). Continue only when they are green.

---

## 1. Product goal (merged)

Career OS is a personal Android app with three areas.

| Area | Keeps | Changes in this project |
|---|---|---|
| **Career** | Jobs, applications, resume vault, salary view, AI job search, cover letter and company research PDFs | The job feed becomes a **resume-driven, AI-verified relevance feed**. It adds a parsed-profile inspector, feedback actions, freshness, and live updates from a companion server and a browser extension. |
| **Freelance** | The ₹1 Cr+ business finder (no site, Shopify, needs a real site), lead pipeline, clients, outreach and proposal docs | No functional change. Only regression-test it. |
| **Track** | LeetCode (500+ synced, 100+ offline), habits, reflection | No functional change. |

**The core principle:** optimise for the number of jobs that are *actually relevant to the user's resume*, not the number of jobs scraped. If 1,000 jobs are discovered and 17 match, the main feed shows those 17.

---

## 2. What exists today (verify every line)

**Stack**
- Flutter 3.47.x with Dart SDK ^3.13; package name `career_os`.
- Riverpod 2 (StateNotifier, StateProvider, family) and Drift SQLite at schema **v10**.
- go_router `StatefulShellRoute` with 4 tabs (Home, Career, Freelance, Track) and a redirect gate for onboarding and AI keys.
- http 1.6, flutter_secure_storage, flutter_local_notifications, pdf, archive, file_picker and open_file.

**AI layer (`lib/core/ai/`)**
- `ai_keys.dart`: `AiProvider {claude, gemini, nemotron}`. Keys live in Android Keystore via secure storage and are loaded before `runApp`.
- `ai_clients.dart`: raw-HTTP clients.
  - `ClaudeClient` uses `claude-opus-5` with adaptive thinking, `output_config.effort`, the `web_search_20260209` server tool, strict client tools and the `server-side-fallback-2026-07-01` beta with `fallbacks: "default"`. It handles `pause_turn` and `refusal`.
  - `GeminiClient` has `pickModel`, which prefers the newest stable "pro" model.
  - `NemotronClient` is OpenAI-compatible and strips `<think>` blocks.
- `ai_service.dart`: `quick()` uses Nemotron and falls back to Claude at low effort. `longForm()` uses Gemini. `verify()` checks a key.
- `document_service.dart`: turns Gemini markdown into PDF or DOCX.

**Jobs**
- Sources are in `lib/features/career/data/job_providers/public_api_job_provider.dart`: `RemoteOkJobProvider`, `RssJobProvider` (WWR), `GreenhouseJobProvider`, `LeverJobProvider` and `AshbyJobProvider` (multi-board).
- `lib/features/career/services/live_job_discovery_service.dart` contains `JobDeduplicator`, `JobDedupIndex` and `LiveJobDiscoveryService.discoverAndSyncJobs`.
- `lib/features/career/services/ai_job_search_service.dart` runs Claude web search. It drops dead links, dedupes, and inserts with `atsProvider='AI_SEARCH'`.
- `lib/features/career/domain/job_match_service.dart` is a **lexical** scorer: skills 45 (dictionary terms), role 30 (title tokens), location 15 and experience 10.
- `lib/features/career/domain/job_search_criteria_builder.dart` also exists.
- `lib/features/career/presentation/live_jobs_view.dart` has `enum JobFilter {all, bestMatch, remote, fresh, saved}`. The **default is `JobFilter.all`**. `bestMatch` means a lexical score of 70 or more.
- `Jobs` table columns: id, title, company, location, salary, employmentType, experienceRequirement, url, source, description, skills, postedDate, discoveredAt, isSaved, notes, atsProvider, rawJson, externalId, createdAt and updatedAt.

**Resume**
- `resume_text_extractor.dart` handles PDF, DOCX, TXT and MD.
  - PDF uses a custom parser with absolute text positioning, ToUnicode, ObjStm and FlateDecode.
  - DOCX reads `word/document.xml`.
- `resume_parser_service.dart` is a dictionary-based parser that produces `ResumeProfile`, defined in `domain/resume_profile_models.dart` (with `ExtractedField<T>` and `WorkExperience`).
- `resume_ingest_service.dart` and `career_profile_sync_service.dart` handle ingest and profile diffs.
- `ats_scoring_service.dart` holds the ATS engine.
- The `Resumes` table has `parsedDataJson` and `extractionStatus`.

**UI**
- `lib/shared/widgets/ui_kit.dart` provides ScreenTitle, SectionHeader, AppCard, StatTile, FilterPills, InitialAvatar, Tag, SearchField and EmptyHint.
- The theme lives in `lib/core/theme/app_theme.dart` (Groww dark: bg #121212, card #1C1C1E, accent #00D09C).

**Tests**
- `test/` holds ai_and_leads, ats_and_parser, database, live_discovery, migration_v9, pipelines, resume_intelligence, resume_text_extractor and widget tests.
- `test_preview/ui_preview_test.dart` is a golden-screenshot harness. It has not been run yet.

**Carried-over unfinished work from the previous session** (finish in M0 or M13):
- Groww-dark restyle of `resume_vault_view`, `salary_insights_view`, `dsa_tab`, `habits_tab`, `reflection_tab`, `onboarding_screen`, `client_details_screen`, `application_details_screen`, `career_profile_view` and the add/edit dialogs.
- `dart fix --apply` for const infos.
- A full `flutter analyze` and `flutter test`.
- A release APK.

**Unused legacy tables** (`Projects`, `Tasks`, `FreelanceLeads`) are left from removed modules. Leave them alone; dropping them is out of scope.

### 2.1 Why irrelevant jobs appear (pre-audit hypothesis: confirm it in `docs/AUDIT.md`)

1. **No relevance gate at ingestion.** Whole Greenhouse, Lever, Ashby, RemoteOK and WWR boards are pulled and every posting is inserted.
2. **The feed defaults to "All".** `filterJobs(..., filter: JobFilter.all)` shows every stored job. Relevance is only an optional pill.
3. **Matching is lexical only.** Title tokens and dictionary-term overlap decide the score, so role meaning is never understood.
   - A "Sales Engineer" or "Solutions Consultant" that mentions Python scores on skills.
   - Generic tokens can still leak through description terms.
4. **The job's role family is never classified.** Nothing rejects a Sales, HR, Civil, Mechanical, Accounting or BD role outright.
5. **Required and preferred skills are never separated**, so a missing *mandatory* stack is never a disqualifier.
6. **AI-search results bypass scoring.** They are inserted directly.
7. **Skill normalization is shallow.** Aliases are handled only as far as the dictionary allows, and there are no rules that keep Java and JavaScript, or React and React Native, apart.

**Step M1 below must reproduce each point with a failing test before fixing it.**

---

## 3. Target architecture

```
┌──────────────────────┐   HTTPS + bearer    ┌─────────────────────────────────────────┐
│ Chrome extension (MV3)│ ─────────────────▶ │ server/  (Dart, shelf, SQLite via drift) │
│  pairing, capture,    │ ◀── config/policy ─ │  auth · ingest · pipeline worker ·       │
│  queue+retry, refresh │                     │  scheduler · SSE · REST · observability  │
└──────────────────────┘                     │  uses packages/career_core               │
                                              └──────────────▲───────────────┬──────────┘
                                   REST + SSE (bearer, HTTPS)  │               │ AI APIs (server env keys)
┌──────────────────────────────────────────────────────────────┴──┐            ▼
│ Flutter app (existing)  Drift = offline cache + local data       │   Claude · Gemini · NVIDIA
│  Connected mode: server is source of truth for jobs/matches      │
│  Standalone mode: runs career_core pipeline on-device (BYOK)     │
└──────────────────────────────────────────────────────────────────┘
```

### Decisions (with reasons)

- **D1: `packages/career_core/` is a pure Dart package with no Flutter imports.** It holds the skill taxonomy, the normalizers, the resume-profile builder, the job normalizer, the role classifier, dedupe keys, the relevance engine, the matching config, the AI provider interfaces, and the source connectors (moved out of `lib/features/career/data/job_providers`).
  - Both the app and the server depend on it through `path:`, so there is one implementation of every rule.
- **D2: `server/` is a Dart backend.** It uses `shelf`, `shelf_router`, `drift` with `sqlite3` in WAL mode, and a `timezone` library.
  - Reason: it is the same language as the app and reuses career_core. SQLite is enough for one user and thousands of jobs, and it survives restarts.
  - Embeddings are stored as float32 BLOBs. Cosine similarity is computed in Dart, which is fast enough at this scale. No vector database.
- **D3: the extension lives in `extension/`.** It is MV3, written in TypeScript and bundled with esbuild. Tests use vitest and jsdom. There is no framework, and the popup and options pages are plain HTML.
- **D4: the app has two modes.**
  - *Standalone* (current behaviour, no server): the app runs the career_core pipeline itself against official sources with the user's own keys.
  - *Connected*: the app pairs with the server. The server owns ingestion, matching and scheduling, and the app mirrors results into Drift.
  - Nothing that works today may stop working when no server is configured.
- **D5: keys.** The server reads its AI keys from environment variables. The phone keeps its own keys in secure storage for on-device features: documents, the business finder, and standalone mode. Keys are never sent between the app, the server and the extension.
- **D6: the job pipeline is a persisted state machine, not a queue.** Each job row carries `pipelineState`. A worker loop inside the server, driven by the scheduler, advances pending rows. Crashes and retries resume cleanly, and unique constraints make retries idempotent.
- **D7: HTTPS.** The server binds `127.0.0.1` by default.
  - Remote access goes through Tailscale (`tailscale serve`, recommended for personal use) or a Cloudflare Tunnel.
  - The server refuses to bind a non-loopback address unless TLS cert paths are set, or `BEHIND_TLS_PROXY=true` is set.
  - The release app accepts only `https://` server URLs. Debug builds may also use `http://10.0.2.2` or `localhost`.

---

## 4. AI model roles (extends the existing roles)

| Job | Provider (default) | Fallback | Where |
|---|---|---|---|
| Live AI job search and ₹1 Cr+ business discovery (web research) | Claude `claude-opus-5` with web_search (existing) | none | app (BYOK) |
| Long documents: proposal, cover letter, research PDF/DOCX (existing) | Gemini, newest stable pro | none | app |
| Quick drafts: outreach, fit check (existing) | Nemotron | Claude, low effort | app |
| **Resume structured extraction** (new) | Claude, strict tool, effort `medium` | Nemotron JSON mode, then deterministic parser only | server + app |
| **Job field extraction from messy text or user selections** (new) | Claude, strict tool, effort `low` | Nemotron | server + app |
| **Embeddings, Layer 2** (new) | Gemini embeddings: pick the newest stable embedding model from the models list, e.g. `gemini-embedding-001`, with `taskType=SEMANTIC_SIMILARITY` and a fixed `outputDimensionality` of 768 | NVIDIA NeMo Retriever embedding model via `integrate.api.nvidia.com/v1/embeddings` (verify the model id at build time) | server + app |
| **Relevance classification, Layer 4** (new) | Claude, strict tool, effort `low`. The candidate profile goes in a cached system block (`cache_control: {type: "ephemeral"}`). | Nemotron JSON, validated against the same schema | server + app |
| Bulk re-scoring after a resume change, when more than 50 jobs need it | Claude Message Batches API (50% cost); poll from the scheduler | normal calls | server |

**Rules for model use**
- Every model id is configuration (`AI_*_MODEL` environment variables on the server, prefs in the app), never a literal inside feature code.
- Verify each model id at startup with the provider's list endpoint, and log the resolved id.
- **Changing the embedding model invalidates the embedding cache.** The cache key includes the model and dimension.

---

## 5. Platform policy (decides what the extension may do)

Create `docs/PLATFORM_POLICY.md` and `packages/career_core/lib/src/sources/platform_policy.dart`.

**Before enabling anything, re-read each platform's current User Agreement or Terms and developer docs.** Record the date, the URL and the clause you relied on.

Defaults, which the agent may only relax with written evidence in that document:

| Platform | Auto DOM extraction | Auto page refresh | User-initiated capture | Profile field automation | Official route |
|---|---|---|---|---|---|
| LinkedIn | **off**: the User Agreement prohibits scraping via bots and browser plugins | **off** | **on**, limited to (a) the "Send selection to Career OS" context menu for text the user selects, and (b) "Save link", which sends only the URL and tab title | **unsupported**: there is no public API for headline/About. Ship assisted mode. | Resolve the posting to the company's own ATS (Greenhouse, Lever, Ashby, Workable or SmartRecruiters public APIs) or career page JSON-LD, then fetch it there |
| Naukri | **off** until verified permitted | **off** | same as LinkedIn | **unsupported** unless an official API is found. Ship assisted mode. | Same resolution strategy. Optional licensed aggregator APIs, after their terms are reviewed. |
| Greenhouse / Lever / Ashby / Workable / SmartRecruiters public boards | n/a: the **server** uses their public JSON APIs | n/a: server polling | "Capture this page" allowed | n/a | public job-board APIs (existing providers) |
| Any page with schema.org `JobPosting` JSON-LD on user-allowlisted domains | on, JSON-LD only | off by default; the user may enable it per domain after a confirmation dialog | on | n/a | the page's structured data |
| Other sources (evaluate and add only if the terms allow) | n/a | n/a | n/a | n/a | Adzuna (has an India endpoint), Jooble, Remotive, Arbeitnow, Himalayas. All need API keys or attribution; follow their rate limits. |

**Assisted profile automation** is the compliant replacement for the "Description A at 08:00, B at 18:00" request:
- At the scheduled time, the app shows a local notification: "Time to switch your Naukri headline to Description B".
- The notification has a **Copy text** action and an **Open edit page** deep link.
- The user saves the change on the platform manually, then taps **Done**.
- The server records the run as `COMPLETED_BY_USER`.
- The rules engine knows the active description, the next scheduled one, the last update and the target platform.
- Any action type marked `unsupported` in the capability registry **cannot be executed**. The engine refuses it and the UI explains why.
- Optional, only if the user asks: posting (not profile editing) through LinkedIn's official "Share on LinkedIn" (`w_member_social`) with 3-legged OAuth, with the token stored server-side and encrypted.

**Page refresh engine:** build it (section 10.4), but it runs only where the policy allows. With the defaults above, it is off for LinkedIn and Naukri. The server's scheduled polling of official sources is the primary way new jobs appear without manual refreshes.

---

## 6. Data model

### 6.1 Server SQLite (`server/lib/db/schema.dart`, drift)

All ids are UUIDv7 text. Timestamps are UTC ISO; convert to Asia/Kolkata only for display and scheduling. Foreign keys are ON, the journal is WAL, and `busy_timeout` is 5000 ms.

**Accounts, devices, audit**

| Table | Columns | Constraints and indexes |
|---|---|---|
| `users` | id, displayName, timezone (default `Asia/Kolkata`), createdAt | |
| `devices` | id, userId→users, kind (`APP`/`EXTENSION`), name, refreshTokenHash, refreshExpiresAt, createdAt, lastHeartbeatAt, lastExtractionAt, lastUploadAt, lastError, revokedAt | index (userId, kind) |
| `access_tokens` | tokenHash PK, deviceId→devices, expiresAt | index expiresAt |
| `pairing_codes` | codeHash PK, userId, createdByDeviceId, expiresAt (10 min), usedAt, attempts | |
| `audit_log` | id, userId, deviceId, action, target, ip, at | index (userId, at) |

**Resumes and candidate profiles**

| Table | Columns | Constraints and indexes |
|---|---|---|
| `resumes` | id, userId, fileName, mime, sha256, sizeBytes, storagePath, isActive, uploadedAt | unique (userId, sha256); partial unique on userId where isActive |
| `resume_profiles` | id, resumeId→resumes, parserVersion, profileJson (CandidateProfile), overridesJson, warningsJson, embeddingKey, createdAt | index resumeId |
| `resume_skills` | profileId→resume_profiles, canonical, category, tier (`PRIMARY`/`SECONDARY`/`FAMILIAR`), evidenceJson | PK (profileId, canonical) |

**Jobs and sources**

| Table | Columns | Constraints and indexes |
|---|---|---|
| `jobs` | id; canonicalUrl; fingerprint; company; companyNorm; title; titleNorm; roleFamily; seniority; location; city; country; workMode (`REMOTE`/`HYBRID`/`ONSITE`/`UNKNOWN`); employmentType; expMinMonths; expMaxMonths; eduRequirement; salaryMin; salaryMax; salaryCurrency; salaryPeriod; descriptionText (sanitised plain text); requirementsText; preferredText; contentHash; postedAt; sourceUpdatedAt; firstSeenAt; lastSeenAt; lastCheckedAt; lastUpdatedAt; status (`OPEN`/`CLOSED`); pipelineState (`RECEIVED`→`NORMALIZED`→`SCORED_DET`→`EMBEDDED`→`LLM_PENDING`→`DONE`, or `FAILED`); pipelineAttempts; pipelineNextAttemptAt; pipelineError | **unique canonicalUrl**; index fingerprint; index companyNorm; index titleNorm; index firstSeenAt; index (pipelineState, pipelineNextAttemptAt) |
| `job_sources` | id, jobId→jobs ON DELETE CASCADE, source, sourceJobId, url, deviceId (nullable), firstSeenAt, lastSeenAt, rawHash | **unique (source, sourceJobId)**; index jobId |
| `job_skills` | jobId→jobs, canonical, requirement (`REQUIRED`/`PREFERRED`/`MENTIONED`), fromTitle (bool) | PK (jobId, canonical) |
| `embeddings` | key PK (sha256(model+dim+text)), model, dim, vector BLOB, createdAt | |

**Matches and feedback**

| Table | Columns | Constraints and indexes |
|---|---|---|
| `job_matches` | userId, jobId, profileId, configVersion, tier (`HIGHLY_RELEVANT`/`RELEVANT`/`POSSIBLE_MATCH`/`NOT_RELEVANT`/`UNSCORED`), score, detScore, llmScore, semantic, componentsJson, skillMatchJson, llmJson, explanation, redFlagsJson, rejectedStage, rejectedReason, evaluatedAt, notifiedAt, seenAt | **PK (userId, jobId)**; index (userId, tier, score DESC); index (userId, evaluatedAt) |
| `job_feedback` | id, userId, jobId, action (`INTERESTED`, `NOT_INTERESTED`, `APPLIED`, `REJECTED`, `ALREADY_APPLIED`, `SAVED`, `UNSAVED`, `HIDE_COMPANY`, `HIDE_ROLE`), createdAt | index (userId, jobId) |
| `hidden_entities` | userId, kind (`COMPANY`/`ROLE_FAMILY`/`TITLE_PATTERN`), value | PK (userId, kind, value) |
| `user_settings` | userId, key, valueJson, updatedAt | PK (userId, key); holds matching config overrides, sources and refresh policy |

**Scheduling, automation, observability**

| Table | Columns | Constraints and indexes |
|---|---|---|
| `scheduled_tasks` | id, userId, kind (`INGEST_SOURCE`, `PIPELINE_WORKER`, `RESCORE_ALL`, `AUTOMATION_RULE`, `CLEANUP`), payloadJson, scheduleJson (`once` or `cron`, plus `jitterMinutes`, window start/end, timezone), nextRunAt, lastRunAt, enabled, failureCount, lockedUntil | index (enabled, nextRunAt) |
| `automation_rules` | id, userId, platform, actionType, capability (`SUPPORTED`/`ASSISTED`/`UNSUPPORTED`), variantsJson (e.g. [{label:"A", text}, {label:"B", text}]), scheduleJson, activeVariant, enabled, createdAt, updatedAt | |
| `automation_runs` | id, ruleId or taskId, scheduledFor, startedAt, finishedAt, status (`SCHEDULED`, `RUNNING`, `SUCCEEDED`, `FAILED`, `RETRYING`, `AWAITING_USER`, `COMPLETED_BY_USER`, `SKIPPED`), attempt, error, detailsJson | index (ruleId, scheduledFor) |
| `ingestion_runs` | id, source, trigger (`SCHEDULE`/`EXTENSION`/`MANUAL`/`AI_SEARCH`), deviceId, startedAt, finishedAt, discovered, parsed, rejectedInvalid, duplicates, accepted, relevantHigh, relevant, possible, notRelevant, errorsJson | index (source, startedAt) |
| `ai_calls` | id, provider, model, purpose, startedAt, latencyMs, ok, errorCode, inputTokens, outputTokens, cacheReadTokens | index (purpose, startedAt) |
| `events` | id INTEGER PK AUTOINCREMENT, userId, type, payloadJson, at | SSE replay; keep 7 days |
| `notifications` | id, userId, type, jobId, title, body, createdAt, deliveredAt | |

### 6.2 App Drift schema v10 → v11 (`lib/core/database/app_database.dart`)

**Steps**
1. Add these columns to `Jobs`: canonicalUrl, fingerprint, roleFamily, seniority, workMode, city, country, expMinMonths, expMaxMonths, contentHash, firstSeenAt, lastSeenAt, lastCheckedAt, sourceUpdatedAt, relevanceTier (default `UNSCORED`), relevanceScore, matchJson, explanation, userState, seenAt, serverId.
2. Add these new tables:
   - `CandidateProfiles`: id, resumeId, parserVersion, profileJson, overridesJson, warningsJson, createdAt
   - `JobFeedbackEntries`
   - `HiddenEntities`
   - `EmbeddingCache`: key, model, dim, vector blob. Used only in standalone mode.
   - `SyncState`: key, value. Holds the server URL, the last event id and the last sync time.
3. Write the migration in this order:
   1. Add the columns.
   2. Backfill `canonicalUrl` and `fingerprint` in Dart using career_core.
   3. **Merge duplicate rows.** Keep the oldest row and re-point `JobApplications.jobId`.
   4. Then create unique indexes: `idx_jobs_canonical` on canonicalUrl where it is not null, and `idx_jobs_source_ext` on (atsProvider, externalId) where externalId is not null.
   5. Set every existing job to `UNSCORED`.
4. Run `build_runner`.
5. Add `test/migration_v11_test.dart`. Start from a v10 database that contains duplicates and an application pointing at a duplicate, and assert that nothing is lost.

**`UNSCORED` jobs never appear in the main feed.** They are scored on the first launch after the upgrade.

---

## 7. Relevance engine specification (`packages/career_core/lib/src/matching/`)

### 7.1 Skill taxonomy (`taxonomy/`)

- `skills.dart` maps each canonical skill (for example `JavaScript`) to:
  - `category`: language, framework, library, database, cloud, devops, frontend, backend, mobile, ai_ml, data, testing or tool
  - `aliases`: e.g. `js`, `ecmascript`, `es6`
  - `kind`: `core` (language, framework or platform) or `supporting`
  - `related`: transferable edges with a weight from 0 to 1, e.g. Kotlin↔Java 0.5, Flutter↔React Native 0.3
- Seed it from the lists in `ResumeParserService.known*` and extend it to at least 400 canonical skills.
- **Equivalences to include (tests required):**
  - JavaScript = JS
  - TypeScript = TS
  - PostgreSQL = Postgres
  - Machine Learning = ML
  - Natural Language Processing = NLP
  - Amazon Web Services = AWS
  - Kubernetes = K8s
  - Golang = Go (only as a word, or in `golang`)
  - C# = csharp
  - .NET = dotnet
  - Node.js = Node = NodeJS
  - React = ReactJS = React.js
- **Non-equivalences to assert:**
  - Java ≠ JavaScript
  - React ≠ React Native
  - Spring ≠ Spring Boot. Related, but separate canonicals, with a `related` weight of 0.7.
  - AWS ≠ Azure ≠ GCP
  - SQL ≠ PostgreSQL. SQL is a generic skill; PostgreSQL *implies* SQL, but not the other way round.
  - C ≠ C++ ≠ C#
  - Go must not match "go-to" or "go live"
  - R must not match stray single letters
- **Implication edges** (having X implies knowing Y): PostgreSQL→SQL, Spring Boot→Spring, Next.js→React, TypeScript→JavaScript, Kotlin/Swift→(mobile only if the context is mobile). Implications count as *equivalent* matches only in the implied direction.
- **The GENERIC stoplist** never counts as a skill and never counts toward role match:
  - software, developer, development, engineer, engineering, programming, coding, technology, technical, IT, computer, digital, data (alone), AI (alone), analytics (alone), cloud (alone), solutions, systems, platform, tools, agile, communication, problem solving, teamwork.
  - "AI" and "data" count only as part of a specific canonical, e.g. "Generative AI / LLMs", "Data Engineering", "Pandas".
- The matcher is regex-free per request. Precompile one tokenizer and matcher that handles punctuation-bearing names (C++, C#, .NET, Node.js, CI/CD), word boundaries, case and plurals.

### 7.2 Candidate profile (`profile/candidate_profile.dart`)

```json
{
  "candidate": {
    "name": "", "currentRole": "", "roles": ["Flutter Developer"],
    "roleFamilies": {"primary": "MOBILE", "adjacent": ["FULLSTACK"]},
    "experienceMonths": 0, "experienceLevel": "JUNIOR|MID|SENIOR|STAFF",
    "education": [{"degree": "", "level": "BACHELOR", "specialization": "", "institution": "", "start": "", "end": "", "score": ""}],
    "skills": {"primary": [], "secondary": [], "familiar": []},
    "frameworks": [], "databases": [], "cloud": [], "devops": [], "ai_ml": [], "testing": [], "tools": [],
    "experience": [{"company": "", "role": "", "start": "", "end": "", "months": 0, "responsibilities": [], "technologies": [], "achievements": [], "evidence": ""}],
    "projects": [{"name": "", "description": "", "technologies": [], "architecture": "", "responsibilities": [], "domain": "", "evidence": ""}],
    "certifications": [], "domains": [], "locations": {"current": "", "preferred": []},
    "careerPreferences": {"remote": "ANY|REMOTE_ONLY|HYBRID_OK|ONSITE_OK", "employmentTypes": ["FULL_TIME"], "relocate": false, "countries": ["IN"]}
  },
  "meta": {"parserVersion": 1, "sourceResumeSha256": "", "warnings": [], "overriddenFields": []}
}
```

**Tier rules (deterministic)**
- **PRIMARY:** appears in two or more experiences, or in the most recent role plus the summary or projects.
- **SECONDARY:** appears once in experience or projects.
- **FAMILIAR:** listed only in a skills section.

**Experience months** are the union of the date ranges in `experience`. Overlapping ranges are not double-counted. "Present" means today in Asia/Kolkata. Internships are counted at half weight, a value that lives in the config.

**Role families** are derived from the experience titles and the preferred roles. The user can edit them in the profile inspector; edits go in `overridesJson`.

### 7.3 Resume pipeline (`profile/resume_pipeline.dart`)

1. **Extract** with the existing `resume_text_extractor.dart`, moved into career_core. Emit text lines with font size and bold flags where the PDF parser already knows them, so headings can be detected. If the extracted text is under 200 characters, treat the PDF as scanned: add a warning and ask the user to paste the text.
2. **Detect sections.** Match headings case-insensitively against a dictionary: summary, experience or work history, projects, education, skills or technical skills, certifications, achievements. Fall back to layout cues: short, bold or uppercase lines followed by body text.
3. **Extract entities deterministically:** email, phone, links, dates and date ranges (`Jan 2022 – Present`, `2021-2023`, `06/2020`), degree keywords, CGPA and percentages, locations (Indian city list plus country names).
4. **Run LLM structured extraction** with the ExtractionProvider (Claude strict tool, whose schema equals the profile above). The rule: **every item must carry an `evidence` string copied verbatim from the resume.** The server drops any item whose evidence is not a substring of the normalised resume text, using a whitespace- and case-insensitive comparison, and logs `droppedUngrounded`.
5. **Merge.** Deterministic results win for dates, contacts and CGPA. The LLM wins for splitting responsibilities and achievements. The union of both is taken for skills after normalisation.
6. **Normalise** skills through the taxonomy, then assign tiers.
7. **Build the profile** and apply the user's overrides on top. A re-parse never discards overrides.
8. **Embed.** Canonical profile text = roles + primary and secondary skills + experience bullets + project descriptions, capped at 6k characters. Store an `embeddingKey`. Also embed each project separately, for the project-similarity component.
9. **Persist** the result, emit `profile.updated`, and schedule a `RESCORE_ALL`.

**If AI is unavailable:** use steps 1–3 and 5–9 without the LLM, set `warnings: ["AI extraction unavailable; profile is keyword-derived"]`, and cap tiers at `POSSIBLE_MATCH` until a grounded profile exists.

### 7.4 Job normalisation (`jobs/job_normalizer.dart`)

**Inputs:** the raw record from a connector, an extension payload or an AI search result.

**Outputs:** a `NormalizedJob` with every column in `jobs` plus `job_skills`.

- **HTML to text:** use a sanitiser that drops script, style and iframe, keeps list and line structure, decodes entities and caps the result at 50k characters.
- **Section splitter:** find the requirements block ("Requirements", "What you'll need", "Must have", "Qualifications", "You have") and the preferred block ("Nice to have", "Preferred", "Bonus", "Plus"). Skills found in the requirements block are `REQUIRED`, in the preferred block `PREFERRED`, and elsewhere `MENTIONED`. Skills in the title are `REQUIRED` with `fromTitle=true`.
- **Experience:** parse `3+ years`, `3-5 yrs`, `minimum 4 years`, `0-2 years`, `fresher`, `10+ yrs` into months, and pick the requirement closest to the role, not "company founded 10 years ago".
- **Seniority** from the title: intern, junior or associate, mid (none), senior, lead or staff, principal or architect, and manager, director, head or VP (a separate *management* track).
- **Location:** city and country from gazetteers. Work mode from the title, location and description ("remote", "hybrid", "WFH", "work from office"). Remote restrictions: "US only", "must reside in", "EU timezone", "authorized to work in the United States", and so on.
- **Employment type:** full-time, part-time, contract, internship or temporary.
- **Education requirement** and whether it is mandatory ("required" or "must" versus "preferred").
- **Salary:** reuse `salary_parser.dart`, moved to core.
- **canonicalUrl:** lowercase the host, strip `utm_*`, `ref*`, `trk*`, `gh_src` and `source`, and drop the fragment. Map known patterns to a canonical form: a LinkedIn `currentJobId` becomes `/jobs/view/{id}`; Greenhouse becomes `boards.greenhouse.io/{board}/jobs/{id}`; Lever becomes `jobs.lever.co/{co}/{id}`.
- **fingerprint:** `sha1(companyNorm | titleNorm | cityOrRemote)`. `companyNorm` drops suffixes such as Pvt Ltd, Private Limited, Inc, LLC, Technologies and Labs. `titleNorm` lowercases, removes seniority noise and requisition numbers, and collapses whitespace.
- **contentHash:** `sha1` of the normalised description. It drives the `UPDATED` freshness.

### 7.5 Role-family classifier (`jobs/role_classifier.dart`)

**Families:**
- Engineering: MOBILE, FRONTEND, BACKEND, FULLSTACK, DATA_ENGINEERING, DATA_SCIENCE_ML, AI_ENGINEERING, DEVOPS_SRE_PLATFORM, QA_TEST, SECURITY, EMBEDDED_FIRMWARE, GAME, ENGINEERING_MANAGEMENT
- Other technical: SALES_ENGINEERING_PRESALES, SOLUTIONS_CONSULTING, PRODUCT_MANAGEMENT, DESIGN, TECHNICAL_WRITING, IT_SUPPORT_ADMIN, DATA_ANALYST_BI
- Non-technical: DATA_ENTRY_ANNOTATION, SALES, BUSINESS_DEVELOPMENT, MARKETING, HR_RECRUITING, FINANCE_ACCOUNTING, OPERATIONS, CUSTOMER_SUPPORT, CIVIL, MECHANICAL, ELECTRICAL, TEACHING_TRAINING, HEALTHCARE, LEGAL, OTHER, UNKNOWN

**Algorithm**
1. **Title rules first.** Use an ordered list of patterns, from most specific to least, including negative patterns: "sales engineer", "account executive", "business development", "recruiter", "talent acquisition", "civil engineer", "mechanical", "accountant", "data entry", "AI trainer", "annotation", and so on. Specific non-software families win over generic words: "Software Sales Manager" becomes SALES.
2. **Title technology hints.** "Flutter", "iOS", "Android" and "React Native" become MOBILE. "Java Developer" becomes BACKEND unless the title also says frontend or full stack.
3. **If still UNKNOWN or ambiguous** (Associate, Analyst, Consultant, a bare "Engineer", "Executive"), classify with the job's first 1,500 characters of responsibilities:
   1. First, embedding nearest-centroid against a one-paragraph description of each family, precomputed and cached.
   2. If the margin is below 0.05, use the LLM classification field `roleFamily`.
4. **Description keywords may never move a job *into* an engineering family when the title rules have already put it in a non-engineering family.** This is the key anti-random-job guarantee.

### 7.6 The pipeline stages (each rejection records `rejectedStage` and `rejectedReason`)

```
S0 SOURCE_VALIDATION → S1 NORMALIZE → S2 DEDUPE/MERGE → S3 ROLE_CLASSIFY → S4 HARD_ELIGIBILITY
→ S5 SKILL_MATCH → S6 SEMANTIC → S7 LLM_CLASSIFY → S8 FUSE+THRESHOLD → S9 PUBLISH (event + notify)
```

**S0: source validation.** Check the schema, field sizes, that the URL host is in the allowlist for the source, and that `postedAt` falls within [now−365d, now+1d]. On failure, count it as `rejectedInvalid` and store nothing but the counter.

**S2: dedupe and merge.** Merging updates `lastSeenAt` and `lastCheckedAt`, adds a `job_sources` row, and fills missing fields. If `contentHash` changed, set `lastUpdatedAt` and re-run from S3. Match candidates in this order:
1. (source, sourceJobId)
2. canonicalUrl
3. fingerprint
4. same `companyNorm`, title trigram similarity ≥ 0.8, and description embedding cosine ≥ 0.97 (only when both embeddings already exist)

**S3: role classify.** If the family is not in `profile.roleFamilies.primary ∪ adjacent ∪ config.alwaysAllowed`, the tier is `NOT_RELEVANT` with reason `ROLE_FAMILY_MISMATCH:<family>`. If the family is `UNKNOWN` after step 3 of the classifier, cap the job at `POSSIBLE_MATCH`.

**S4: hard eligibility** (all thresholds live in the config). Each of these is `NOT_RELEVANT` with the reason shown:
- `EXPERIENCE_GAP`: `job.expMinMonths > candidate.months + tolerance` (default 18 months).
- `SENIORITY_MISMATCH`: `rank(job.seniority) − rank(candidate.level) ≥ 2`, or the job is on the management track and the candidate has no management history.
- `INTERNSHIP_ONLY`: the job is an internship and the candidate is not seeking internships.
- `LOCATION`: the job is onsite or hybrid, its city is not in the preferred list, the candidate won't relocate, and the candidate is `REMOTE_ONLY` or has no matching city.
- `REMOTE_REGION`: the job is remote with a region restriction that excludes the candidate's country.
- `MANDATORY_STACK`: the job lists two or more `REQUIRED` core skills and the candidate has zero of them, counting exact, alias and implied matches.
- `TITLE_STACK`: the job title names a core technology the candidate lacks entirely, with no `related` edge of weight ≥ 0.5.
- `EDUCATION`: the job states a mandatory degree level above the candidate's.
- `HIDDEN_COMPANY` or `HIDDEN_ROLE`: the user hid the company, role family or title pattern.
- A missing *preferred* skill is **never** a reason for rejection.
- Being over-qualified is a soft penalty, never a rejection.

**S5: skill match.** Compare `job_skills` against the candidate. Produce these lists, each with the evidence phrase from the job text:
- `exact`
- `equivalent` (alias or implication)
- `transferable` (related edge, with its weight)
- `missingRequired`
- `missingPreferred`

**Skill score:**

`skillScore = 100 × (Σ w(match) over REQUIRED + 0.5 × Σ w(match) over PREFERRED) / (|REQUIRED| + 0.5 × |PREFERRED|)`

- w is 1.0 for an exact match, 0.9 for an equivalent, the edge weight × 0.6 for a transferable skill, and 0 for a missing one.
- A candidate skill counts for more by tier: ×1.0 for PRIMARY, ×0.85 for SECONDARY, ×0.6 for FAMILIAR.
- **If a job has no REQUIRED or PREFERRED skills after extraction, the score is `null` and the job is capped at `POSSIBLE_MATCH`.** Never default to a high score.

**S6: semantic similarity.**
- Compute cosine(profile embedding, job embedding). The job text is the title + requirements + responsibilities, capped at 4k characters.
- Compute projectSim as the maximum cosine between each project embedding and the job embedding.
- If `semantic < config.semanticFloor`, the job is `NOT_RELEVANT` with reason `LOW_SEMANTIC`.
- **Calibrate `semanticFloor`** on the labelled fixture set (section 12.2) for the chosen embedding model. Set it to the midpoint between the 95th percentile of NOT_RELEVANT jobs and the 10th percentile of RELEVANT-or-better jobs. Record the numbers in `docs/CALIBRATION.md`. Recalibrate whenever the model changes.
- **If embeddings are unavailable, skip this stage and cap the job at `POSSIBLE_MATCH`.**

**S7: LLM classification.**
- Runs only if the job survived S3–S6 **and** `detScore ≥ config.llmGateMin` (default 45).
- **Input:**
  - the system block holds the rules and the candidate profile JSON, cached
  - the user block holds the normalised job, the S5 lists and the S4 soft flags
- **Output:** strict tool `record_job_match`:

```json
{"isRelevant": true, "confidence": 0.0, "roleFamily": "", "relevanceScore": 0, "roleMatch": 0, "skillMatch": 0,
 "experienceMatch": 0, "educationMatch": 0, "domainMatch": 0, "locationMatch": 0, "reason": "",
 "matchedSkills": [{"skill": "", "jobEvidence": ""}], "missingImportantSkills": [{"skill": "", "jobEvidence": "", "mandatory": true}],
 "redFlags": [""]}
```

- **Validate the output server-side before using it:**
  - Clamp every score to 0–100.
  - Keep a `matchedSkills[].skill` only if it normalises to a candidate canonical skill. Drop the rest and increment `hallucinationDropped`.
  - Every `jobEvidence` must be a substring of the job text; otherwise drop the item.
  - `reason` must be 400 characters or fewer, must not name skills absent from both sides, and is otherwise replaced with the deterministic explanation.
- **The LLM can demote a job but cannot overturn S3 or S4.** It is never called for rejected jobs.
- **On failure:** retry with exponential backoff (1s, 4s, 16s plus jitter) on 429, 5xx, `overloaded` or a network error. After three attempts, set `LLM_PENDING` with `pipelineNextAttemptAt` 30 minutes later. A circuit breaker opens after five consecutive failures for five minutes.

**S8: fuse and threshold.**
- `detScore = Σ weight_i × component_i` over the components role, skill, semantic, experience, project, domain, education and location, each scored 0–100. The weights come from the config.
- `final = round(α × detScore + (1 − α) × llm.relevanceScore) + feedbackAdj`, with α = 0.55 by default. `feedbackAdj` is bounded to [−15, +5] (section 11.3).
- Tiers:

| Tier | Condition |
|---|---|
| `HIGHLY_RELEVANT` | final ≥ 80 **and** llm.isRelevant **and** llm.confidence ≥ 0.7 **and** missingRequired core skills = 0 **and** no red flag from the blocking list |
| `RELEVANT` | final ≥ 65 **and** llm.isRelevant **and** missingRequired core skills ≤ 1 |
| `POSSIBLE_MATCH` | final ≥ 50, **or** any cap applied (LLM pending or unavailable, no embeddings, UNKNOWN role family, null skill score, profile not grounded) with detScore ≥ 55 |
| `NOT_RELEVANT` | everything else |

- **The main feed shows `HIGHLY_RELEVANT` and `RELEVANT` only.** "Needs review" shows `POSSIBLE_MATCH`. "Filtered out" (debug, hidden by default) shows `NOT_RELEVANT` with the stage and reason.

**S9: publish.**
- If the tier is RELEVANT or better and the job was not published before, insert an `events` row of type `job.matched` and push it over SSE.
- If the tier is HIGHLY_RELEVANT, also create a notification.
- A job is never re-announced as new. `notifiedAt` guards this.

### 7.7 Matching config (`matching/matching_config.dart` plus `server/config/matching.json`)

This is a single immutable object, JSON-serialisable and versioned. **No other file may contain a weight or threshold literal.** Add a test that greps for stray numeric thresholds in `matching/` outside the config.

```json
{
  "version": 1,
  "weights": {"role": 0.22, "skill": 0.30, "semantic": 0.18, "experience": 0.12, "project": 0.06, "domain": 0.04, "education": 0.03, "location": 0.05},
  "alpha": 0.55,
  "thresholds": {"high": 80, "relevant": 65, "possible": 50, "llmGateMin": 45, "semanticFloor": 0.0, "llmMinConfidenceHigh": 0.7},
  "experienceToleranceMonths": 18, "internshipWeight": 0.5, "seniorityMaxGap": 1,
  "overqualifiedPenalty": 8, "feedbackAdjMin": -15, "feedbackAdjMax": 5,
  "alwaysAllowedFamilies": [], "familyAdjacency": {"MOBILE": ["FULLSTACK", "FRONTEND"], "BACKEND": ["FULLSTACK", "DEVOPS_SRE_PLATFORM"]},
  "blockingRedFlags": ["unpaid", "commission only", "bond", "security deposit", "pay to apply"]
}
```

- The value `semanticFloor: 0.0` is only a placeholder. **You must calibrate it (S6) before shipping.**
- The weights must sum to 1.0. Validate this at load time.
- A change to the config bumps `configVersion` and schedules `RESCORE_ALL`.

### 7.8 Explanations (`matching/explainer.dart`)

These are deterministic and built only from stored data:
- the header: `MATCH 87% · Highly relevant`
- **Matched:** exact and equivalent skills, with any aliases in parentheses
- **Relevant experience:** experience or project entries whose technologies intersect the matched skills, or whose embedding sim is ≥ 0.75
- **Missing:** required and preferred skills, labelled as such
- **Reason:** the validated LLM reason if present, otherwise a template like "Strong {family} alignment; {n}/{m} required skills; {gap note}"

The card shows the one-line reason and the top four matched skills.

### 7.9 Freshness

| Label | Condition |
|---|---|
| `NEW` | `firstSeenAt` within 24 hours and `seenAt` is null |
| `UPDATED` | `lastUpdatedAt` within 48 hours and after `firstSeenAt` + 1 hour |
| `RECENT` | `postedAt ?? firstSeenAt` within 7 days |
| `OLD` | everything else. After 30 days without being seen, `status` becomes `CLOSED` and the job is hidden. |

Opening a job's details sets `seenAt`.

---

## 8. Milestones: do them in this order

Each milestone lists its tasks, files and **exit checks**. Do not start the next milestone until the exit checks pass.

### M0: Baseline

1. Run `flutter pub get`, `flutter analyze` and `flutter test`. Record the counts in `docs/AUDIT.md`, and fix anything already red. Then run `dart fix --apply` and fix the remaining infos.
2. Optionally render `test_preview/ui_preview_test.dart` with `flutter test test_preview --update-goldens` to capture the current UI for later comparison. Keep `test_preview/` out of the default `flutter test` run.
3. **Exit:** analyze reports 0 issues and all tests are green.

### M1: Audit and reproduce the bad-feed bug

1. Write `docs/AUDIT.md` covering:
   - the inventory in section 2, corrected against the code
   - every job-related file and what it does
   - the existing sources, dedupe, matching, filters, notifications and background work (check whether any workmanager or periodic task exists)
   - the root causes in section 2.1, each with file:line references
2. Add `test/relevance_regression_test.dart` using the **current** code. It must show these failures:
   - a Sales Manager posting that mentions "software" and "Python" appears under `JobFilter.all`
   - a keyword-bait "AI Trainer (Python)" job scores 50 or more
   - a "Senior Java Developer" job gets a skill match for a candidate who only knows JavaScript
   - an AI-search job is inserted without scoring
3. Mark these tests `skip:` with a reason. They are turned into passing tests in M7.
4. **Exit:** the audit document exists and the failures are reproduced.

### M2: Monorepo scaffolding

1. Create `packages/career_core/`:
   - `pubspec.yaml`: pure Dart, depending on `http`, `archive`, `crypto`, `collection` and `meta`
   - `lib/career_core.dart` (exports) and `lib/src/{taxonomy,profile,jobs,sources,matching,ai,dedupe,util}/`
2. Move the pure logic out of `lib/` into core, keeping the old import paths working only until M13, then removing them:
   - `resume_text_extractor.dart`
   - `resume_parser_service.dart` (becomes the deterministic part of the pipeline)
   - `resume_profile_models.dart` (evolves into CandidateProfile; keep a converter from the old `ResumeProfile` JSON for existing `parsedDataJson` rows)
   - `salary_parser.dart`
   - `public_api_job_provider.dart` (as `sources/connectors/*.dart`, one file per source)
   - `feed_utils.dart`
   - `JobDedupIndex` (replaced by the dedupe in 7.6 S2)
3. Move the AI HTTP clients into `career_core/lib/src/ai/` behind interfaces (M8). The app keeps `ai_keys.dart` (secure storage), which is Flutter-only.
4. Add `career_core: {path: packages/career_core}` to the app's `pubspec.yaml`.
5. Create a `server/` skeleton:
   - `bin/server.dart`, `lib/{config,db,http,auth,pipeline,scheduler,sse,observability}/`
   - `test/`, `config/matching.json`, `.env.example`
6. Create an `extension/` skeleton:
   - `manifest.json`, `src/{background,popup,options,content,shared}/`
   - `package.json` with the scripts `build`, `test` and `zip`
   - `tsconfig.json` and `esbuild.config.mjs`
7. **Exit:**
   - `dart test` passes in `packages/career_core`
   - `flutter analyze` reports 0 and `flutter test` is green (no behaviour change)
   - `dart run server/bin/server.dart --help` works
   - `npm run build` in `extension/` works

### M3: Taxonomy and normalisation (section 7.1)

1. Implement `taxonomy/skills.dart`, `taxonomy/skill_matcher.dart`, `taxonomy/generic_stoplist.dart` and `util/text_normalize.dart`.
2. Add `test/taxonomy_test.dart` covering every equivalence, non-equivalence, implication, the stoplist, and edge tokens (C++, C#, .NET, Node.js, CI/CD, Go versus "go", R).
3. **Exit:** the tests are green and matching 10k characters takes under 5 ms on a laptop (add a micro-benchmark test with a generous bound).

### M4: Resume pipeline and candidate profile (sections 7.2 and 7.3)

1. Implement `profile/candidate_profile.dart` (with `fromJson`/`toJson` and the legacy converter), `profile/section_detector.dart`, `profile/entity_extractors.dart`, `profile/experience_calculator.dart`, `profile/skill_tiering.dart` and `profile/resume_pipeline.dart`.
2. The ExtractionProvider interface is used here, with a fake in tests.
3. Add fixtures under `packages/career_core/test/fixtures/resumes/`:
   - a two-column PDF
   - a single-column PDF
   - a DOCX
   - a TXT file
   - a resume with no Projects section
   - a resume with no dates
   - a malformed PDF (truncated xref)
   - a scanned PDF (image only)
   - an empty file

   Generate the PDFs with the `pdf` package inside the test setup where possible, so no personal data is committed.
4. Tests must cover:
   - section detection
   - experience months with overlaps and "Present"
   - skill tiers
   - the grounding filter that drops ungrounded LLM items
   - that overrides survive a re-parse
   - graceful warnings on malformed or scanned input
5. **App:** replace `resume_ingest_service.dart` so it uses the pipeline, storing to `CandidateProfiles` in standalone mode or uploading to the server in connected mode.
6. **Exit:** the core tests and app tests are green.

### M5: Normalised jobs and role classifier (sections 7.4 and 7.5)

1. Implement `jobs/normalized_job.dart`, `jobs/html_sanitizer.dart`, `jobs/section_splitter.dart`, `jobs/experience_parser.dart`, `jobs/location_parser.dart` (with `assets/in_cities.txt` and a countries list), `jobs/seniority.dart`, `jobs/role_classifier.dart`, `jobs/canonical_url.dart` and `jobs/fingerprint.dart`.
2. Build a table-driven test of 60 or more titles mapped to families, including these traps:
   - "Software Sales Manager" → SALES
   - "Sales Engineer" → SALES_ENGINEERING_PRESALES
   - "Data Entry Operator" → DATA_ENTRY_ANNOTATION
   - "AI Trainer – Python" → DATA_ENTRY_ANNOTATION
   - "Business Development Executive – SaaS" → BUSINESS_DEVELOPMENT
   - "Civil Engineer – AutoCAD" → CIVIL
   - "Mechanical Design Engineer" → MECHANICAL
   - "Accountant (Tally, Excel, data)" → FINANCE_ACCOUNTING
   - "HR Executive (HRMS, Python basics)" → HR_RECRUITING
   - "Java Developer" → BACKEND
   - "Flutter Engineer" → MOBILE
   - "Full Stack (React/Node)" → FULLSTACK
   - "Python Instructor" → TEACHING_TRAINING
   - "Associate" → UNKNOWN
3. **Exit:** tests are green.

### M6: Sources, ingestion and dedupe (sections 5 and 7.6 S0–S2)

1. Define the `sources/source_connector.dart` interface: `id`, `displayName`, `policy`, `fetch(query) → Stream<RawJob>`, and `rateLimit` (requests per minute and minimum interval).
2. Port the existing connectors: Greenhouse, Lever, Ashby, RemoteOK, WWR RSS and Remotive if present. **Keep the existing curated board lists.**
3. Add optional connectors behind config and keys, only after checking their terms: Adzuna (India), Jooble, Arbeitnow, Himalayas, Workable and SmartRecruiters public postings.
4. Add `sources/jsonld_jobposting.dart`, which parses schema.org JobPosting. It is used by both the extension payload handler and "resolve to official source".
5. Add `sources/official_resolver.dart`. Given a captured LinkedIn or Naukri URL plus a title and company (or a selection), it tries to find the same posting in this order:
   1. the company's known ATS board, via the connectors
   2. the company's careers-page JSON-LD
   3. Claude web search restricted to the company domain (reuse `ClaudeClient.research`)

   The resolved record becomes the canonical source. The platform URL is kept only as a `job_sources` row.
6. Add `ingest/ingestion_service.dart`: `ingest(List<RawJob>, trigger, deviceId) → IngestionRunSummary`. It runs S0 → S1 → S2 in one transaction per batch, writes `ingestion_runs`, and sets `pipelineState=NORMALIZED` for new or changed jobs.
7. **The AI job search must go through `ingest()`.** Delete its direct insert.
8. Tests:
   - normal, incomplete and malformed jobs
   - the same job ingested five times (from the same source, from a different source, and with a tracking-param URL) produces **one** row, five `lastSeenAt` updates and two `job_sources` rows
   - a changed description sets `UPDATED`
   - retrying a batch creates no duplicates
9. **Exit:** tests are green.

### M7: Relevance engine, deterministic layers (section 7.6 S3–S6, S8 and 7.7–7.9)

1. Implement `matching/hard_filters.dart`, `matching/skill_scorer.dart`, `matching/component_scorers.dart`, `matching/fusion.dart`, `matching/matching_config.dart`, `matching/explainer.dart`, `matching/freshness.dart`, and `matching/relevance_engine.dart`, which orchestrates the stages with injected providers.
2. **Delete `lib/features/career/domain/job_match_service.dart`** and replace every usage with the engine output stored on the job (`relevanceTier`, `relevanceScore`, `matchJson`, `explanation`).
3. Build the fixture corpus (section 12.2) and `test/matching_corpus_test.dart`, with the LLM and embeddings faked from recorded fixtures.
4. Un-skip the M1 regression tests; they must now pass.
5. **Exit:** on the corpus:
   - **0 NOT_RELEVANT-labelled jobs appear in HIGH or RELEVANT (precision is 100%)**
   - 90% or more of HIGH-labelled jobs are HIGH or RELEVANT
   - every job in the main feed has a non-empty explanation

### M8: AI provider abstraction (sections 4 and 20 of the original specification)

1. In `career_core/lib/src/ai/`, create these interfaces:
   - `EmbeddingProvider` with `embed(List<String>, {taskType}) → List<Float32List>` and `modelId`
   - `ExtractionProvider` with `extractResume(text) → Map` and `extractJob(text) → Map`
   - `MatchingProvider` with `classify(profileJson, jobJson, findings) → LlmMatch`
   - `AiRouter`, which picks the primary provider and a fallback per purpose from config, adds a circuit breaker and retries, and records `ai_calls`
2. Implement them:
   - `ClaudeMatchingProvider` and `ClaudeExtractionProvider`, reusing the existing raw-HTTP `ClaudeClient` with strict tools and the cached system block
   - `GeminiEmbeddingProvider`, using `models/{m}:batchEmbedContents` with the `x-goog-api-key` header, at most 100 texts per call, with the model picked from the list and pinned in config
   - `NvidiaEmbeddingProvider` (with `input_type` passage or query) and `NemotronMatchingProvider` (JSON output validated by the same schema validator)
   - `FakeProviders` for tests
3. Add an `EmbeddingCache` (the server's `embeddings` table or the app's `EmbeddingCache`) keyed by `sha256(model|dim|text)`.
4. Graceful degradation: when no provider exists for a purpose, the engine applies the caps from S6, S7 and S8, and the UI shows "AI check pending".
5. **Tests:**
   - Mock HTTP for every provider: request shape, auth header, error mapping, retry and backoff on 429/529, circuit breaker, and the hallucination filter.
   - Cache hits avoid HTTP calls.
6. **Exit:** tests are green, plus one **optional** live smoke test (`tool/ai_smoke.dart`) run only when the keys are in the environment. State in the report whether it ran.

### M9: Server core, auth and APIs (sections 9 and 10)

1. Add `server/lib/db/`: the drift schema from 6.1, migrations and a WAL connection.
2. Add `server/lib/config/`: load environment variables, validate them, and fail fast with clear messages (section 14).
3. Add `server/lib/auth/`, which never uses passwords:
   - **Owner bootstrap.** On the first run, if there are no users, print a one-time `SETUP CODE` (8 characters, valid 30 minutes) to the console. The app's "Connect to server" screen exchanges it at `POST /api/v1/auth/bootstrap` for APP device tokens.
   - **Access tokens** are random 32-byte base64url strings with a 15-minute TTL, stored as sha256.
   - **Refresh tokens** last 60 days, rotate on every use, and are stored as sha256. Reuse of a rotated token revokes the device (theft detection).
   - **Pairing.** The app calls `POST /api/v1/devices/pairing-codes`, which returns a 6-digit code valid for 10 minutes, single-use, locked after 5 attempts. The extension calls `POST /api/v1/extension/auth` with `{code, deviceName}` and receives EXTENSION tokens.
   - **Authorisation:**
     - EXTENSION devices may only call ingest, heartbeat and extension config
     - APP devices may call everything
     - every query is scoped by `userId`
4. Add `server/lib/http/`: shelf pipeline middleware in this order:
   1. request id
   2. structured logging with redaction (Authorization, cookies, tokens, codes and keys are never logged)
   3. security headers: `Strict-Transport-Security` when behind TLS, `X-Content-Type-Options: nosniff`, `Referrer-Policy: no-referrer`, `Content-Security-Policy: default-src 'none'` for JSON, `X-Frame-Options: DENY`
   4. CORS: allow only the `chrome-extension://<EXTENSION_IDS>` origins; answer other preflights with 403
   5. body size limit (1 MB JSON, 5 MB resume)
   6. auth
   7. rate limits: a token bucket per device and per IP, e.g. ingest 60 per minute, batch 10 per minute, pairing and auth 5 per minute per IP, returning 429 with `Retry-After`
   8. the error mapper (no stack traces in responses)
   9. Idempotency: honour `Idempotency-Key` on POSTs and store the responses for 24 hours.
5. **CSRF:** not applicable, because there are no cookies and all calls use bearer tokens. Document this in `docs/SECURITY.md`.
6. **SQL:** use drift with bound parameters only. Grep-test that there is no string-interpolated SQL.
7. **XSS:** job descriptions are stored as sanitised plain text, and the app renders them as text, never as HTML.
8. Implement the endpoints in section 9 with request validation from a single schema per endpoint (`server/lib/http/validation.dart`). Unknown fields get 400.
9. Wire the pipeline worker. The scheduler task `PIPELINE_WORKER` runs every 30 seconds and processes up to 25 rows where `pipelineState IN (NORMALIZED, SCORED_DET, EMBEDDED, LLM_PENDING)` and `nextAttemptAt <= now`, with LLM concurrency 3. **Exactly one worker runs, enforced by a `lockedUntil` lease.**
10. Tests use `shelf` handler tests with an in-memory SQLite database:
    - 401 without a token, 401 with an expired token
    - 403 when an extension calls an app-only endpoint
    - a revoked device is rejected
    - refresh-token reuse revokes the device
    - a pairing code expires and locks out after 5 attempts
    - ingest validation: an oversized body, a non-https URL, a wrong host for the source, a `<script>` in the description (stored as text), unknown fields
    - 429 with `Retry-After`
    - a CORS preflight from another origin gets 403
    - idempotent replay
    - logs contain no token or code strings (capture the log sink and assert)
11. **Exit:** server tests are green and `dart compile exe server/bin/server.dart` succeeds.

### M10: Scheduler and automation (sections 5 and 10.5)

1. Add `server/lib/scheduler/`: persisted `scheduled_tasks`, a tick every 15 seconds, and a lease lock.
   - Schedules: `once(at)`, `interval(minutes, jitterMinutes)`, `daily(times[], jitterMinutes, windowStart, windowEnd)` and `cron(expr)`. All are evaluated in the task's timezone (default `Asia/Kolkata`) using the `timezone` package.
   - **Jitter** is drawn uniformly inside [scheduled − jitter, scheduled + jitter] ∩ window and stored in `nextRunAt`, so it survives a restart. Its purpose is to spread load, not to disguise traffic.
   - **Retry:** exponential backoff at 1, 5 and 25 minutes, capped at 3 retries, then `FAILED` with the error. Every attempt writes an `automation_runs` row.
   - **Missed runs** (the server was down): on startup, run each overdue task **once** and skip the extra missed occurrences, recording them as `SKIPPED`.
2. Seed these default tasks:
   - `INGEST_SOURCE` per enabled source, every 3 hours with 20 minutes of jitter
   - `PIPELINE_WORKER` every 30 seconds
   - `CLEANUP` daily at 03:30 IST: prune events and old tokens, close stale jobs
   - `RESCORE_ALL` on demand
3. Add `server/lib/automation/`:
   - a capability registry: `platform × actionType → SUPPORTED | ASSISTED | UNSUPPORTED`
   - rules CRUD
   - the executor: `ASSISTED` produces `AWAITING_USER` and emits an `automation.due` event; `UNSUPPORTED` is refused at create time and at run time
   - `POST /automation/runs/:id/complete`
4. **App:** the app schedules local notifications for `ASSISTED` rules with `flutter_local_notifications` `zonedSchedule` in Asia/Kolkata, re-synced on every rules change and on app start. Actions: *Copy text*, *Open edit page*, *Mark done*. Standalone mode works entirely on-device.
5. Tests use a fake clock:
   - recurring tasks
   - IST conversion
   - jitter stays inside the window
   - retry and backoff, then FAILED
   - restart persistence: create the scheduler, add a task, dispose it, create a new scheduler on the same database file, and the due task runs once
   - missed-run policy
   - an UNSUPPORTED action is refused
6. **Exit:** tests are green.

### M11: Live updates (section 9, `/events`)

1. **Server:** `GET /api/v1/events` serves SSE with `text/event-stream`, a heartbeat comment every 25 seconds, `id:` set to `events.id`, and replay from `Last-Event-ID`. Event types: `job.matched`, `job.updated`, `profile.updated`, `automation.due` and `ingestion.completed`.
2. **App:** add `lib/core/sync/server_sync_service.dart`.
   - In the foreground, it keeps SSE open with an exponential reconnect and applies events by fetching `/jobs/:id` and upserting into Drift.
   - On resume or start, it calls `GET /jobs/recommended?updatedSince=<last>` to catch up.
   - Background: if no periodic worker exists, add one with a minimum 15-minute interval that polls `recommended` and raises a local notification for new `HIGHLY_RELEVANT` jobs. Verify on a device, or say it wasn't verified.
3. Tests:
   - SSE handler replay
   - the app sync service with a fake server: event → Drift row → provider emits
4. **Exit:** tests are green.

### M12: Browser extension (sections 5 and 10)

1. Write `manifest.json` (MV3):
   - `permissions`: `storage`, `alarms`, `contextMenus`, `activeTab`, `scripting`, `notifications`
   - `host_permissions`: the backend URL (configured at build or in options, via `optional_host_permissions`) and the ATS domains
   - **no `<all_urls>`**, and **no `cookies` or `webRequest`**
   - **No content script is declared for LinkedIn or Naukri.**
2. `src/background/`:
   - `auth.ts`: pairing, token storage in `chrome.storage.local` (never `sync`), refresh on 401, and a logout/revoke button
   - `queue.ts`: an IndexedDB outbox with idempotency keys, exponential backoff with full jitter (2s to 30 min), an offline check, and flushing on `online` or an alarm
   - `heartbeat.ts`: every 15 minutes, via `chrome.alarms`
   - `pageDetector.ts`: URL-pattern classification into `SEARCH_RESULTS`, `JOB_DETAILS`, `PROFILE`, `FEED` or `OTHER` per platform, from the tab URL only
   - `policy.ts`: fetched from `GET /extension/config` and cached. It is the single place that gates each capability.
   - `refresh.ts`: the refresh engine (10.4)
3. `src/content/jsonld.ts`: injected **only** with `chrome.scripting.executeScript` on user action ("Capture this page") or on allowlisted ATS domains. It reads `script[type="application/ld+json"]` JobPosting only and never reads cookies, storage or unrelated DOM.
4. Context menu actions:
   - "Send selection to Career OS" sends `{source: "manual_selection", pageUrl, pageType, selectionText (≤20k)}`
   - "Save job link" sends `{source, url, title}`
5. `popup.html`: connection status, last heartbeat, last upload, queue length, capture buttons and the policy state per current site. `options.html` holds the server URL, device name, per-domain refresh settings (with a confirmation for anything not policy-approved), and pair or unpair.
6. **Never send** cookies, localStorage, page HTML dumps, the user's own profile data or other people's data. Payloads carry only job fields.
7. Tests (vitest + jsdom), using **synthetic** fixtures only:
   - page detection by URL
   - JSON-LD extraction from normal, missing and malformed fixtures
   - queue: offline → queued → online → flushed exactly once (fake fetch)
   - 401 → refresh → retry
   - refresh-token rejected → state `UNPAIRED`
   - policy gate blocks refresh on LinkedIn and Naukri
   - the refresh scheduler respects min/max, jitter, visibility and backoff
8. **Exit:** `npm test` is green and `npm run build && npm run zip` produces `extension/dist/career-os-extension.zip`.

### M13: Flutter app (UI and wiring), Groww dark

1. **Server connection:** add `lib/features/settings/presentation/server_connection_screen.dart`.
   - It has a URL field (https-only in release), a setup-code exchange, a paired state and an unpair button.
   - It creates pairing codes for the extension, showing a big 6-digit code and a countdown.
   - APP tokens are stored in secure storage.
2. **Mode switch:** when connected, disable the on-device source fetchers and let the server own jobs. Otherwise the standalone pipeline runs through career_core inside the existing "refresh" and auto-sync.
3. **Career › Jobs** (rewrite `live_jobs_view.dart`):
   - **Segments:** **For you** (HIGHLY_RELEVANT + RELEVANT, the default), **Needs review** (POSSIBLE_MATCH), **Saved** and **Applied**.
   - **"Filtered out"** is only visible when Settings › Matching › "Show filtered jobs (debug)" is on. It lists the rejection stage and reason.
   - **Remove `JobFilter.all`.** There is no "All" view anywhere.
   - **Quick pills:** Remote, New today and Best (≥80).
   - **Filter sheet:** relevance tier, source, location or city, role family, experience range, work mode, posted date (24h, 3d, 7d, 30d), company, and skills (multi-select from the matched skills).
   - Filters are pure functions in `career_core` or `lib/features/career/domain/job_filters.dart`, with unit tests. Keep FilterPills counts.
   - **Empty states** are honest: "No jobs match your resume strongly yet. 23 are waiting in Needs review."
4. **JobCard** shows:
   - title, company, location, work mode
   - source and a posted/freshness badge (NEW, UPDATED, RECENT)
   - a score ring (%) in the tier colour
   - up to four matched-skill chips, and one missing chip in warning colour
   - a one-line reason
   - actions: save, not interested (swipe or menu), applied
   - tap to open the details

   There must be no overflow at 320 dp width or at text scale 1.3.
5. **Job details** (`job_details_screen.dart`):
   - A match breakdown with component bars and the matched, equivalent, transferable, missing-required and missing-preferred lists with evidence.
   - Relevant experience, red flags, the reason, and a freshness line (first seen, last seen, updated).
   - Sources, with "View original" for each.
   - A feedback menu: Interested, Not interested, Applied, Already applied, Hide company, Hide this role type, Save.
   - Keep the existing Quick fit check, Cover letter PDF and Company research PDF actions.
6. **Resume › Parsed profile:** add `lib/features/career/presentation/profile_inspector_screen.dart`.
   - It shows every section of the CandidateProfile with evidence snippets, the tiers and the warnings.
   - Target role families and preferences can be edited, and edits are saved as overrides.
   - It has **Re-parse** and **Set active resume** actions.
   - Replace `career_profile_view.dart` if this makes it redundant; delete what is no longer used.
7. **Settings**, grouped:
   - **Resume:** the active resume, re-parse, and view the parsed profile
   - **Job matching:** minimum tier for notifications, preferred roles and locations, experience range, remote preference, and the show-filtered debug toggle. Advanced weights are read-only, with a "reset to defaults" button.
   - **Sources:** enable or disable each connector, with each one's last run and counts
   - **Extension:** connection status, last heartbeat, last extraction, last upload, enabled, and pair or unpair
   - **Automation:** the rule list, the active and next description, the timezone, the jitter window, and supported actions (UNSUPPORTED ones are shown greyed out with the reason)
   - **Server**
   - **AI keys** (existing)
   - **Appearance**
   - **About**
8. **System status screen** (`/settings/status`): recent ingestion runs with their counts; AI stats (evaluated, per tier, errors, p50/p95 latency); extension status; scheduler state (next runs, failures).
9. **Home:** the "Top job matches" card uses HIGH and RELEVANT only; add a "Needs review: n" chip. Keep the existing Freelance and Track cards.
10. **Carried-over UI work:** finish the Groww-dark restyle of the screens listed in section 2, and remove leftover buttons and sections that do nothing.
11. Delete the dead code: `job_match_service.dart`, the old filter enum values, the direct-insert paths and the unused widgets. Run `flutter analyze` to prove nothing references them.
12. Widget tests:
    - the feed shows no NOT_RELEVANT or UNSCORED jobs
    - the filter sheet narrows the results
    - a feedback action hides the job
    - the inspector renders the fixture profile
    - there is no overflow at 320×640 dp at text scale 1.3 (use `tester.view` sizes)
13. **Exit:** analyze reports 0 and all tests are green. Optionally, golden previews re-rendered and reviewed.

### M14: Feedback loop (section 16 of the original specification)

1. `matching/feedback_model.dart` computes `feedbackAdj` for each job from the user's history:
   - NOT_INTERESTED or REJECTED on a job whose embedding cosine to this one is ≥ 0.9: −8 each, capped
   - repeated rejections in the same role family (3 or more in 30 days): −5
   - repeated rejections of the same company: −5
   - INTERESTED, SAVED or APPLIED on similar jobs: +2 each, capped at +5
   - The result is clamped to the config's [min, max] and **is never applied to jobs rejected at S3 or S4.**
2. HIDE_COMPANY and HIDE_ROLE write `hidden_entities`, which acts as a hard filter at S4.
3. APPLIED or ALREADY_APPLIED creates or links a `JobApplication` in the app (reuse `convertJobToApplication`) and removes the job from "For you".
4. Tests: the adjustment is bounded, feedback cannot promote a job past a hard filter, and hide rules apply at the next scoring.
5. **Exit:** tests are green.

### M15: Observability

1. Structured JSON logs on the server (level, time, requestId, event, fields) with a **redaction list**. Add a test that feeds a secret through every log call site pattern.
2. Counters are persisted in `ingestion_runs`, `ai_calls` and `automation_runs`, and in `devices` (heartbeat, last extraction, last upload, errors).
3. `GET /api/v1/status` returns an aggregate for the app's status screen. `GET /healthz` returns `{ok:true}` only and needs no auth.
4. **Exit:** the status endpoint is tested.

### M16: End-to-end, builds and report

1. `tool/e2e_test.dart` (Dart; runs the server in-process on a temporary database with fake AI and fake connectors):
   1. bootstrap an app device
   2. create a pairing code
   3. pair an extension
   4. upload the fixture resume
   5. wait for the profile
   6. POST the full fixture job corpus through `/jobs/batch-ingest` as the extension, including duplicates and tracking-param URLs
   7. run the pipeline worker until it is idle
   8. assert that `/jobs/recommended` equals exactly the expected HIGH and RELEVANT set, that `/jobs/review` holds the expected POSSIBLE set, and that no unrelated job (Sales, HR, Civil, Mechanical, Accountant, BD, keyword-bait) appears in either
   9. assert that the SSE client received a `job.matched` event for each recommended job, and none for the others
   10. post feedback and assert a similar job drops
   11. restart the server on the same database and assert that the scheduler resumes and no duplicates appear
2. **Live E2E (optional, only with keys set):** the same flow with real Claude and Gemini on 20 fixture jobs. Record the precision and recall in `docs/CALIBRATION.md`, and state in the report whether it ran.
3. Run the builds:
   - `flutter analyze` (0 issues) and `flutter test`
   - `dart test` in `packages/career_core` and in `server`
   - `npm test && npm run build && npm run zip` in `extension`
   - `dart compile exe server/bin/server.dart -o build/career_os_server.exe`
   - `flutter build apk --release`
4. Verify the APK and report its path and size.
5. Regression-check the Freelance business finder and Track by running their existing tests. They must stay green.
6. Write `docs/RUNNING_LOCALLY.md` and `docs/SECURITY.md`, then write the final report (section 15).

---

## 9. API (`/api/v1`, JSON, bearer auth unless noted)

**Auth and devices**

| Method | Path | Who | Notes |
|---|---|---|---|
| POST | /auth/bootstrap | none (setup code) | `{setupCode, deviceName}` → `{accessToken, refreshToken, expiresIn}` |
| POST | /auth/refresh | any | Rotates the refresh token |
| POST | /devices/pairing-codes | APP | → `{code, expiresAt}` |
| GET | /devices · POST /devices/:id/revoke | APP | |
| POST | /extension/auth | none (pairing code) | `{code, deviceName, extensionVersion}` → tokens |
| POST | /extension/heartbeat | EXT | `{version, queueLength, lastExtractionAt, lastError?}` |
| GET | /extension/config | EXT | The platform policy, refresh settings per domain and allowed sources |

**Resumes**

| Method | Path | Who | Notes |
|---|---|---|---|
| POST | /resumes | APP | multipart, ≤5 MB, PDF, DOCX or TXT checked by **magic bytes**, not the extension |
| GET | /resumes/current · GET /resumes/profile | APP | |
| PATCH | /resumes/profile | APP | Overrides only |
| POST | /resumes/:id/reparse · POST /resumes/:id/activate | APP | |

**Jobs**

| Method | Path | Who | Notes |
|---|---|---|---|
| POST | /jobs/ingest | EXT, APP | A single job. `Idempotency-Key` supported. |
| POST | /jobs/batch-ingest | EXT, APP | ≤50 jobs → `{accepted, duplicates, rejected:[{index, reason}]}` |
| POST | /jobs/capture | EXT | `manual_selection` or a link: AI extraction plus the official resolver, then ingest |
| GET | /jobs | APP | Filters: `tier`, `source`, `location`, `roleFamily`, `expMin`, `expMax`, `workMode`, `postedWithin`, `company`, `skill`, `freshness`, `updatedSince`, `cursor`, `limit ≤ 100`. **Default `tier=HIGHLY_RELEVANT,RELEVANT`.** |
| GET | /jobs/recommended · /jobs/review · /jobs/filtered | APP | Shortcuts. `/filtered` is the debug view. |
| GET | /jobs/:id · /jobs/:id/match | APP | |
| POST | /jobs/:id/feedback | APP | `{action}` (section 6.1); `/save` and `/reject` are aliases |
| POST | /jobs/:id/seen | APP | |

**Settings, automation, status**

| Method | Path | Who | Notes |
|---|---|---|---|
| GET/PATCH | /settings/matching · /settings/sources | APP | PATCH bumps `configVersion` and triggers a re-score |
| GET/POST | /automation/rules · PATCH/DELETE /automation/rules/:id | APP | UNSUPPORTED is rejected with 422 and a reason |
| GET | /automation/runs · POST /automation/runs/:id/complete | APP | |
| GET | /events | APP | SSE |
| GET | /status | APP | Observability aggregate |
| GET | /healthz | none | `{ok:true}` |

**Ingest payload** (validated server-side and never trusted):

```json
{"source": "greenhouse|lever|ashby|workable|smartrecruiters|jsonld|linkedin|naukri|manual_selection|ai_search",
 "sourceJobId": "≤128 chars [A-Za-z0-9._:-]", "url": "https only, host allowlisted for source",
 "title": "1–200", "company": "1–150", "location": "≤200", "workMode": "REMOTE|HYBRID|ONSITE|null",
 "employmentType": "≤40", "experience": "≤120", "salary": "≤120", "description": "≤50k, sanitised to text",
 "skills": ["≤60 items, ≤60 chars each"], "postedAt": "ISO-8601|null",
 "metadata": {"whitelisted keys only, ≤4KB"}}
```

**Errors** use the envelope `{error: {code, message, requestId}}`.

---

## 10. Extension behaviour details

- **10.1 Page detection** uses URL patterns kept per platform in `shared/platforms.ts`. Unknown pages are `OTHER`, and nothing happens on them.
- **10.2 Extraction:**
  - JSON-LD first. On allowlisted ATS pages, stable selectors are a fallback, kept in per-domain adapters with a version stamp.
  - On failure, report the extraction error through the heartbeat. Never guess.
  - AI extraction happens **on the server** (`/jobs/capture`), never in the extension.
- **10.3 Upload:** use the outbox. Every item has a UUID idempotency key. HTTP 4xx other than 401 or 429 means drop the item and log it. 401 means refresh the token, then retry. 429 or 5xx means back off.
- **10.4 Refresh engine** (only where `policy.autoRefresh === true` for the domain):
  - Per-tab settings `{minMinutes ≥ 30, maxMinutes ≤ 240, jitter uniform in [min, max]}`.
  - Run only while the tab exists and the browser is not idle (`chrome.idle`). If the tab is hidden, defer until it becomes visible, or skip if `requireVisible` is set.
  - Stop after 3 consecutive errors, or on any 403, 429 or CAPTCHA/interstitial detection. **Never try to solve or avoid a challenge.** Show a notification and disable refresh for that domain for 24 hours.
  - Log every refresh through the heartbeat.
  - Defaults ship **disabled** for LinkedIn and Naukri, per section 5.
- **10.5 Profile descriptions:** the extension does **not** edit profiles. Assisted automation lives in the app and server (section 5).

---

## 11. Additional rules

- **11.1 Dedupe guarantees:** unique constraints on `canonicalUrl` and on `(source, sourceJobId)`, plus the transactional merge in S2. A retried request with the same idempotency key returns the stored response.
- **11.2 Error handling:**
  - One failing connector never fails a run; its errors go in `ingestion_runs.errorsJson`.
  - When the AI is down, jobs stay in `LLM_PENDING` or are capped as `POSSIBLE_MATCH`.
  - SQLite `SQLITE_BUSY` is retried with backoff.
  - An expired token leads to a refresh, and a failed refresh leads to the unpaired state.
  - When the network is down, the extension outbox and the app's Drift cache keep working.
- **11.3 Feedback bounds** are listed in M14. They are never applied to hard-filtered jobs.
- **11.4 Privacy:**
  - Store no platform passwords, cookies or session tokens anywhere.
  - Resume files stay on the server disk under `server/data/resumes/` with 0600 permissions (or the Windows equivalent: a user-only ACL). The app deletes local copies only on request.

---

## 12. Tests and fixtures

### 12.1 Test inventory (all must exist and pass)

- **career_core:** taxonomy, normalisation, resume pipeline (PDF, DOCX, TXT, malformed, missing sections, scanned, empty), job parser (normal, incomplete, malformed, duplicate), role classifier, hard filters, skill scorer, fusion, thresholds, explainer, freshness, dedupe, config validation, AI providers (mock HTTP), feedback model.
- **server:** auth, pairing, authorisation, validation, sanitisation, rate limit, CORS, idempotency, log redaction, pipeline worker (resume after a crash, no duplicates after a retry), scheduler (recurring, timezone, jitter, failure, retry, restart persistence, missed runs), automation capability refusal, SSE replay, status endpoint.
- **extension:** auth, extraction, upload, retry, offline, reconnect, page detection, policy gate, refresh engine.
- **app:** migration v11, sync service, filters, feed widget, inspector, no-overflow, plus the existing suites (Freelance, Track, AI, documents).
- **e2e:** `tool/e2e_test.dart`.

### 12.2 Labelled fixture corpus (`packages/career_core/test/fixtures/`)

- **Two candidate profiles**, to prove the engine is resume-driven and not hard-coded:
  - **A:** a Flutter/mobile developer with about 3 years, Dart, Flutter, Riverpod, Firebase, Kotlin basics, REST, SQLite, in Bengaluru, open to remote.
  - **B:** a Java backend developer with about 4 years, Java, Spring Boot, REST, PostgreSQL, Angular, Docker, in Pune.
- **At least 60 synthetic but realistic jobs**, each labelled with the expected tier *for each* profile. They must include:
  1. Strong match: "Flutter Developer", SDE-2 Mobile Flutter, "Backend Engineer – Java/Spring Boot"
  2. Completely unrelated: Sales Manager, HR Executive, Civil Engineer, Mechanical Engineer, Accountant, Business Development Executive, Customer Support
  3. Generic keyword overlap only: an HR role whose description is full of "software", "data", "AI" and "Python", a Data Entry "AI data" role, "AI Trainer – Python", a "Technical Sales Engineer" mentioning Java and cloud, a "Python Instructor"
  4. Good role with one missing *preferred* skill: Flutter + "nice to have GraphQL"; Spring Boot + "Kubernetes preferred". The expected tier is RELEVANT or HIGH.
  5. Mandatory mismatch: "iOS Engineer – Swift/SwiftUI required" (for A), "Golang Backend Engineer – Go required" (for B), "React Native Developer" (for A: related, not equivalent; expected POSSIBLE or NOT, as labelled)
  6. Seniority mismatch: Principal Engineer 12+ years, Engineering Manager, Director
  7. Location: onsite Mumbai (A won't relocate: NOT), remote "US only" (NOT), remote India (OK), hybrid Bengaluru (OK)
  8. Also: an internship for a full-time seeker, a duplicate with a tracking-param URL, a job with no skills, a job with an HTML/script-laden description, and a job with a changed description (UPDATED)
- **Recorded fake LLM responses and embeddings** for each (profile, job) pair, stored as JSON. Include at least one hallucinated matchedSkill, to prove the validator drops it.
- **Acceptance on the corpus:**
  - **Precision of the main feed is 100%.**
  - HIGH-labelled recall is 90% or more.
  - Every NOT label is rejected at the stage the label expects.

---

## 13. Commands (run after every milestone that touches the area)

```bash
flutter pub get && dart run build_runner build --delete-conflicting-outputs
flutter analyze            # must print "No issues found!"
flutter test
(cd packages/career_core && dart pub get && dart analyze && dart test)
(cd server && dart pub get && dart analyze && dart test)
(cd extension && npm ci && npm run lint && npm test && npm run build && npm run zip)
dart run tool/e2e_test.dart
flutter build apk --release   # report build/app/outputs/flutter-apk/app-release.apk size
```

---

## 14. Environment variables (`server/.env.example`; never commit real values)

| Var | Req | Meaning |
|---|---|---|
| `PORT` | no (8787) | HTTP port |
| `BIND_HOST` | no (127.0.0.1) | Non-loopback requires TLS or `BEHIND_TLS_PROXY=true` |
| `TLS_CERT_PATH`, `TLS_KEY_PATH` | cond. | Direct TLS |
| `BEHIND_TLS_PROXY` | no | true when behind Tailscale or Cloudflare |
| `PUBLIC_BASE_URL` | yes | e.g. `https://pc.tailnet.ts.net` |
| `DATA_DIR` | no (`server/data`) | SQLite database and resume files |
| `EXTENSION_ORIGINS` | yes | Comma list of `chrome-extension://<id>` |
| `APP_TIMEZONE` | no (Asia/Kolkata) | |
| `ANTHROPIC_API_KEY` | yes* | Extraction and matching (*the engine degrades without it) |
| `GEMINI_API_KEY` | yes* | Embeddings |
| `NVIDIA_API_KEY` | no | Fallback extraction, matching and embeddings |
| `AI_MATCHING_MODEL`, `AI_EXTRACTION_MODEL`, `AI_EMBEDDING_PROVIDER`, `AI_EMBEDDING_MODEL`, `AI_EMBEDDING_DIM` | no | Overrides; the defaults are in section 4 |
| `ADZUNA_APP_ID`, `ADZUNA_APP_KEY`, `JOOBLE_API_KEY` | no | Optional connectors |
| `LOG_LEVEL` | no (info) | |

---

## 15. Final report (write it in chat, and save it as `docs/IMPLEMENTATION_REPORT.md`)

1. What was already present.
2. What was broken, with file:line references for the root causes.
3. What you changed.
4. The new files created.
5. The existing files modified or deleted.
6. Database changes: server schema, app v10→v11 migration.
7. API changes.
8. Extension changes, including the permissions requested and why.
9. The AI models and providers used, per purpose, with the model ids actually resolved.
10. How resume matching works (stages S0–S9).
11. How the relevance thresholds work, plus the calibration numbers.
12. How to run the complete system locally: server, Tailscale or Cloudflare exposure, app pairing, extension pairing.
13. The required environment variables.
14. How to install and load the extension: `chrome://extensions`, Developer mode, Load unpacked `extension/dist`, copy the extension id into `EXTENSION_ORIGINS`, then pair.
15. How to test the entire workflow: the commands and the manual steps.
16. Platform-specific functionality that cannot be automated through officially supported mechanisms. These are the LinkedIn and Naukri extraction, refresh and profile edits, with the policy evidence and the assisted alternatives shipped.
17. **A test-evidence table:** each command run, its pass/fail status, and the counts. List **anything not tested**, such as a real device, real LinkedIn or Naukri pages, background polling on Android, or live AI calls.
18. The APK path and size, and the server binary path.

Do not mark any acceptance criterion as done unless the evidence table shows it was tested.
