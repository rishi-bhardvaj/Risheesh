# Comprehensive Job Intelligence Audit

## 1. Inventory Verification (against codebase)

- **Flutter / Dart Stack**:
  - Flutter 3.47.x, Dart SDK ^3.13, package name `career_os` in `pubspec.yaml`.
  - State management: Riverpod 2 (`flutter_riverpod: ^2.6.1`).
  - Persistence: Drift SQLite at schema version 10 (`lib/core/database/app_database.dart:714`).
  - Navigation: `go_router: ^14.8.1` with `StatefulShellRoute` in `lib/core/routing/app_router.dart`.
  - Networking & Utilities: `http: ^1.2.2`, `flutter_secure_storage: ^9.2.4`, `flutter_local_notifications: ^18.0.1`, `pdf: ^3.11.1`, `archive: ^4.0.2`, `file_picker: ^8.1.7`, `open_file: ^3.5.10`.

- **AI Layer (`lib/core/ai/`)**:
  - `ai_keys.dart`: `AiProvider {claude, gemini, nemotron}`. Keys stored in Android Keystore via `flutter_secure_storage`.
  - `ai_clients.dart`: Raw HTTP clients for Claude (`claude-opus-5`, tool use, fallbacks), Gemini (`pickModel`, `models/gemini-*`), and Nemotron (`integrate.api.nvidia.com`).
  - `ai_service.dart`: `quick()`, `longForm()`, `verify()`.
  - `document_service.dart`: Converts markdown output to PDF / DOCX.

- **Job Discovery & Ingestion**:
  - `lib/features/career/data/job_providers/public_api_job_provider.dart`: Contains `RawJobItem`, `JobProvider`, `RemoteOkJobProvider`, `RssJobProvider`, `GreenhouseJobProvider`, `LeverJobProvider`, `AshbyJobProvider`.
  - `lib/features/career/services/live_job_discovery_service.dart`: Contains `JobDedupIndex`, `JobDeduplicator`, and `LiveJobDiscoveryService.discoverAndSyncJobs`.
  - `lib/features/career/services/ai_job_search_service.dart`: Claude web search, dead link checks, direct insert into `Jobs` table bypassing match filters.
  - `lib/features/career/domain/job_match_service.dart`: Lexical scoring (Skills 45, Role 30, Location 15, Experience 10).
  - `lib/features/career/presentation/live_jobs_view.dart`: Segmented filtering via `filterJobs()` with `JobFilter { all, bestMatch, remote, fresh, saved }`. Default selection is `JobFilter.all`.
  - Background Work: **No workmanager or background daemon exists**. Job syncing is only triggered via UI lifecycle (`initState` in `LiveJobsView`) or manual refresh.

---

## 2. Job-Related Files & Responsibilities

| File Path | Responsibility |
|---|---|
| `lib/features/career/data/job_providers/public_api_job_provider.dart` | Fetches raw job postings from RemoteOK, WWR RSS, Greenhouse, Lever, and Ashby. |
| `lib/features/career/services/live_job_discovery_service.dart` | Orchestrates multi-provider discovery, basic deduplication (`JobDedupIndex`), and persistence to Drift `Jobs`. |
| `lib/features/career/services/ai_job_search_service.dart` | Runs Claude with tool use and web search to locate jobs; checks HTTP 200/404; directly inserts into Drift `Jobs`. |
| `lib/features/career/domain/job_match_service.dart` | Computes a lexical match score (0-100) using token intersections and dictionary lookups. |
| `lib/features/career/domain/job_search_criteria_builder.dart` | Builds suggested search queries from active resumes and user profile. |
| `lib/features/career/presentation/live_jobs_view.dart` | UI view for live job discovery, filter pills, search bar, and job cards. |
| `lib/features/career/presentation/job_details_screen.dart` | Displays job details, matching factors, gap factors, and action buttons. |
| `lib/features/career/providers/career_providers.dart` | Riverpod providers for jobs, applications, resumes, and discovery state. |

---

## 3. Existing Ingestion, Deduplication, Matching, and Filtering Analysis

1. **Ingestion**:
   - `LiveJobDiscoveryService.discoverJobs()` queries all registered providers concurrently (`Future.wait`).
   - Every raw job is converted to a Drift `JobsCompanion` without any pre-qualification, relevance gating, or role verification.

2. **Deduplication**:
   - `JobDeduplicator` matches by normalized URL (`cleanUrl`) and `title.toLowerCase() + company.toLowerCase()`.
   - Lacks URL canonicalization (stripping UTM tracking params, normalizing company/job-board hostnames).
   - Lacks fingerprint hashing or content hashing.

3. **Matching**:
   - `JobMatchService.calculateMatch()` is purely lexical.
   - It computes dictionary term intersections between profile text and job text.
   - It treats "software" or "python" in an HR or Sales posting as valid technical skill overlaps.
   - It does not distinguish required vs. preferred skills.
   - It does not classify role families (e.g. Sales, HR, Civil Engineering).

4. **Filtering**:
   - `live_jobs_view.dart` defaults to `JobFilter.all`.
   - `JobFilter.all` returns `true` for every job in SQLite (`lib/features/career/presentation/live_jobs_view.dart:34`).
   - Consequently, 100% of discovered postings (including non-software, sales, or unrelated roles) are rendered in the main feed.

5. **Notifications & Background Work**:
   - Notifications exist in `flutter_local_notifications` for application status or alerts, but no background sync service or periodic worker is registered.

---

## 4. Root Causes for Irrelevant Jobs in Feed (with File:Line References)

1. **No Ingestion Relevance Gate**:
   - `lib/features/career/services/live_job_discovery_service.dart:104-122`:
     Every job fetched from external ATS boards or RemoteOK is immediately converted into a `JobsCompanion` and written to the database.
2. **Default Feed View Shows Everything (`JobFilter.all`)**:
   - `lib/features/career/presentation/live_jobs_view.dart:33-39`:
     The default filter is `JobFilter.all`, where `switch (filter) { JobFilter.all => true, ... }` unconditionally passes every job to the view.
   - `lib/features/career/presentation/live_jobs_view.dart:49`:
     `final jobFilterSelectionProvider = StateProvider<JobFilter>((ref) => JobFilter.all);`
3. **Lexical-Only Matching Scoring Engine**:
   - `lib/features/career/domain/job_match_service.dart:81-95`:
     Skills are scored based on simple dictionary substrings found anywhere in `job.title`, `job.skills`, and `job.description`.
   - `lib/features/career/domain/job_match_service.dart:90-94`:
     If dictionary terms are sparse, it falls back to checking if user terms are contained anywhere in the raw job text, awarding 22 points merely for mentioning a user term.
4. **Absence of Role-Family Classification**:
   - `lib/features/career/domain/job_match_service.dart:97-108`:
     Only evaluates token intersections with generic words removed. Roles like "Sales Manager", "HR Specialist", "Civil Engineer", or "Accountant" are not classified into non-engineering families and thus are not rejected.
5. **Lack of Required vs Preferred Skill Separation**:
   - `lib/features/career/domain/job_match_service.dart:82-89`:
     Skills are treated uniformly without section splitting ("Requirements" vs "Nice to have"). Missing core mandatory skills does not trigger disqualification.
6. **AI-Search Results Bypass Relevance Verification**:
   - `lib/features/career/services/ai_job_search_service.dart:122-124`:
     AI web search jobs are batch-inserted directly into `db.jobs` with `atsProvider='AI_SEARCH'` without any scoring or qualification checks.
7. **Shallow Skill Normalization**:
   - `lib/features/career/domain/job_match_service.dart:38-43`:
     Relies on flat string lists in `ResumeParserService` without semantic aliasing, directional implications (e.g. Postgres -> SQL), or negative rules (Java != JavaScript, React != React Native).
