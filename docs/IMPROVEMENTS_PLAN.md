# Career OS: Improvements Plan (stability, salary, notifications, AI load, tailored resumes, UI)

This plan covers the 10 issues reported after the last build. It is written so that a coding agent can execute it step by step in this repo.

**Findings are marked ✅ when verified in the code (29 Sep 2026) and 🔎 when they are likely but not yet proven.** No phone was connected when this was written, so the crash itself has not been reproduced yet.

**Relation to `JOB_INTELLIGENCE_IMPLEMENTATION_PROMPT.md`:** that plan was only partly carried out.
- `packages/career_core` exists, and its relevance engine passes 11 tests. The app does not use it yet; only `job_filters.dart` imports it.
- `server/` and `extension/` are skeletons.
- `profile_inspector_screen.dart`, `system_status_screen.dart`, `IMPLEMENTATION_REPORT.md`, `RUNNING_LOCALLY.md` and `SECURITY.md` are **empty files**.

**Do this plan first.** It fixes the app you actually use, and it reuses `career_core` for match scoring. The server and extension stay paused until this plan is done.

---

## 0. Rules for whoever implements this

1. Work phase by phase, in the order of section 12. After each phase, run `flutter analyze` (it must report 0 issues) and `flutter test` (all green).
2. Merge every schema change into **one Drift migration, v10 → v11**, with a migration test. The job-intelligence prompt also planned v11 columns, so fold them in here rather than making two migrations.
3. Never invent resume content (section 8). Never claim a feature works without running it. List anything that needs a real phone to verify.
4. Do not commit unless asked.

---

## 1. App crashing and slow

### What's wrong
- ✅ **Match scoring runs inside `build()`, repeatedly.**
  - `live_jobs_view.dart:89-97` calls `filterJobs()` six times on every build: five times for the pill counts and once for the list.
  - Each call runs `JobMatchService.calculateMatch()` for **every** job. That function runs several hundred regular expressions over the job text, and a description can be up to 12,000 characters.
  - Typing in the search box triggers a rebuild on every keystroke.
  - `home_screen.dart` runs `filterJobs(bestMatch)` again.
  - With around 800–1,000 board jobs, this blocks the UI thread for seconds, which Android reports as "App not responding". That looks exactly like a crash.
- ✅ **Every jobs screen loads the whole jobs table.** `watchAllJobs()` is `select(jobs).watch()` (`app_database.dart:893`). It loads every column, including `description` and the full `rawJson` payload, and emits again after every insert during discovery. Five screens watch it.
- ✅ **The database grows fast.** Discovery stores the entire raw API payload in `rawJson` for every job.
- ✅ **Nothing records crashes.** There is no `FlutterError.onError`, no `PlatformDispatcher.onError` and no error screen, so a crash leaves no trace.
- 🔎 **Other risks:**
  - Memory pressure (the app could be killed for running out of memory) from holding all jobs plus descriptions.
  - Long `AlertDialog` forms overflowing when the keyboard opens.
  - PDF generation on the UI thread.

### Steps
1. **Crash capture** (`lib/core/diagnostics/crash_reporter.dart`):
   - Wrap `main()` so that `FlutterError.onError`, `PlatformDispatcher.instance.onError` and `Isolate.current.addErrorListener` all write to a rolling log (`<app docs>/logs/crash-YYYYMMDD.log`, keeping the last 20 files).
   - In release builds, set `ErrorWidget.builder` to a friendly card instead of a grey screen.
   - Add **Settings › Diagnostics** with "View log" and "Share log".
2. **Reproduce the crash once on a phone:** run `adb logcat -b crash -b main *:E flutter:V` while opening the Jobs tab and running a refresh. Record the stack in `docs/AUDIT.md`. If the crash is native (out of memory, keystore, sqlite), fix that specifically.
3. **Score once, when jobs are saved, never during `build()`:**
   - Add these columns to `Jobs` in v11: `matchScore INT`, `matchTier TEXT`, `matchJson TEXT`, `matchProfileVersion TEXT`, `roleFamily TEXT`, `isRemote BOOL`, `salaryMinInr REAL`, `salaryMaxInr REAL`.
   - Add `lib/features/career/services/job_scoring_service.dart`. It runs `career_core`'s engine inside `Isolate.run`, in batches of 200.
   - It is triggered in two cases:
     - after discovery inserts jobs
     - when the resume or profile changes (a new `profileVersion` hash means re-score everything in the background, with a small "Updating matches…" banner)
4. **Light list queries and paging:**
   - Add a `JobListItem` projection with no `description` and no `rawJson`.
   - Add `watchJobPage({tier, remote, freshSince, saved, salaryMinInr, query, limit: 50, offset})`. Filters run in SQL, ordered by `matchScore DESC, discoveredAt DESC`, with infinite scroll.
   - Pill counts come from one `GROUP BY` query.
   - Search is debounced by 300 ms and uses `LIKE` on title and company.
   - Details screens load the full row by id.
5. **Put the database on a diet:**
   - Stop storing `rawJson` and keep it null.
   - Cap descriptions at 8,000 characters.
   - Once after the migration, clear the existing `rawJson` values and `VACUUM`.
   - Delete jobs older than 30 days unless they are saved or applied to.
6. **Discovery:** decode JSON in an isolate (`feed_utils.dart` already uses `compute`). Insert each source's results in one batch transaction. The other sources keep going if one fails.
7. **Rebuild hygiene:**
   - Use `ref.watch(provider.select(...))` for small values.
   - Use `ListView.builder` or slivers for every list that can be long: DSA (500+ problems), jobs, leads.
   - Use const widgets where possible.
   - Generate PDFs in `Isolate.run`.
8. **Startup:** keep `main()` minimal. Initialise notifications, the background worker registration and auto-sync **after the first frame**.
9. **Checks:**
   - A test inserts 2,000 jobs into an in-memory database; a page query with filters and counts must finish in under 50 ms.
   - A widget test types into the search box; no scoring may run in `build()` (spy on the engine).
   - On a phone in a `flutter run --profile` build, open the Jobs tab and refresh. There must be no frame over 100 ms in DevTools, and no ANR.

---

## 2. Expected salary with a currency converter; jobs filtered by it

### Steps
1. **Profile fields** (v11 `UserProfiles`): `expectedSalaryAmount REAL`, `expectedSalaryCurrency TEXT` (default `INR`), `expectedSalaryPeriod TEXT` (`YEAR`/`MONTH`), `displayCurrency TEXT` (default `INR`). Migrate the old free-text `expectedSalary` with the salary parser (e.g. "18 LPA" becomes 1,800,000 INR per year).
2. **Onboarding and Edit profile:** add an amount field, a searchable currency dropdown (INR, USD, EUR, GBP, AED, SGD, CAD, AUD, JPY, CHF, then all ISO codes the rates API returns), and a per year / per month toggle. Show a live hint such as "≈ $21,400 / yr".
3. **Exchange-rate service** (`lib/core/fx/fx_service.dart`):
   - Fetch `https://api.frankfurter.app/latest?from=INR` (European Central Bank rates, free, no key, includes INR). Cache the result in a new `FxRates` table with a timestamp and refresh once a day.
   - If that fails, use `open.er-api.com/v6/latest/INR`. If both fail, use a bundled rates snapshot and show "Rates as of <date>" in the UI.
   - Provide `convert(amount, from, to)`.
4. **Normalise job salaries when jobs are saved:**
   - Parse the salary text with the existing salary parser, moved into `career_core`, then extend it. Cases to handle:
     - `₹12 LPA`, `12–18 lakhs`, `1.2 Cr`
     - `$120k–150k`, `€5,000/month`, `$60/hr` (hourly × 2,080 for a yearly figure)
     - `CTC`, and ranges with or without a currency symbol
   - Where connectors return structured salary data (Lever, Ashby, RemoteOK), use it.
   - Store `salaryMinInr` and `salaryMaxInr` as **yearly INR**.
5. **Filtering and fetching:**
   - Add a **"Meets my salary"** filter pill: the job's `salaryMaxInr` must be at least 90% of the expected yearly INR figure. The tolerance lives in config.
   - Jobs without a salary are shown with a "Salary not listed" tag by default, because most Indian and ATS postings don't list one and a hard filter would hide most jobs. A toggle **"Hide jobs without salary"** changes that.
   - Add a "Salary" sort option.
   - Pass the salary to sources that accept it: Adzuna's `salary_min`, and AI search prompts ("salary at least ₹X/yr").
6. **Display:** show salaries in `displayCurrency`, with the original amount underneath, for example "₹42L–55L / yr · orig. $50k–65k". Add a small **converter card** to the Salary tab: amount, from and to dropdowns, and a swap button.
7. **Tests:**
   - parser cases (all the formats above)
   - conversion both ways
   - the rates fallback order
   - the salary filter, including the "not listed" behaviour
   - migrating the old free-text value

---

## 3 and 9. Notifications (none arrive today)

### What's wrong
- ✅ `flutter_local_notifications` is in `pubspec.yaml`, but **nothing in `lib/` initialises or calls it**.
- ✅ The manifest has no `POST_NOTIFICATIONS` permission, which Android 13+ requires.
- ✅ There is no background worker (confirmed in `docs/AUDIT.md`), so new jobs are only fetched while the Jobs tab is open.

### Steps
1. **Setup:**
   - Add `workmanager`, `timezone` and `flutter_timezone`.
   - Enable core-library desugaring in `android/app/build.gradle.kts`; `flutter_local_notifications` requires it.
   - Add the manifest entries: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, and the plugin's `ScheduledNotificationReceiver` and `ScheduledNotificationBootReceiver`.
   - Use **inexact** scheduling (`AndroidScheduleMode.inexactAllowWhileIdle`), so the Play-restricted exact-alarm permission isn't needed.
2. **`lib/core/notifications/notification_service.dart`:**
   - Channels: `jobs` (high), `leads`, `habits`, `leetcode`, `applications` (high), `reflection`, `digest`.
   - Tapping a notification carries a route in its payload, which opens it through go_router. Cold starts are handled with `getNotificationAppLaunchDetails()`.
   - Add a `NotificationLog` table (a unique `key` plus `sentAt`), so the same job, lead or reminder is never announced twice.
3. **Permission:** add an onboarding step called "Stay on top of things" that explains the notifications and then asks. Add the same prompt in Settings. If the user denies it, show a banner with an "Open settings" link.
4. **Background worker** (`lib/core/background/background_tasks.dart`, workmanager):
   - Every 3 hours (Android's minimum is 15 minutes), with a network constraint and battery-not-low.
   - It fetches the non-AI job sources, scores the jobs in an isolate, and saves them. It then notifies **"N new jobs match your resume"**: jobs with `matchTier ≥ RELEVANT` that haven't been notified before, grouped into one notification with the top job in the text. At most 3 job notifications per day.
   - The same run also re-schedules the reminders listed below.
5. **The notifications:**

| Type | When | Content, tap target |
|---|---|---|
| New matching jobs | background worker | "3 new jobs match your resume · Senior Flutter Engineer at Razorpay (92%)" → Jobs, For you |
| Interview reminder | 1 day and 1 hour before `interviewDate` | → application |
| Application follow-up | on `followUpDate` at 10:00 | "Follow up with Swiggy (applied 7 days ago)" → application |
| New potential leads | after a lead scan finishes | "5 new ₹1 Cr+ businesses without a website" → Freelance |
| Lead follow-up | a lead in CONTACTED or PROPOSAL with no update for 3 days | → lead |
| Habit reminder | each habit's own time (new `Habits.reminderTime` column) | skipped if the habit is already done that day |
| LeetCode daily | user-chosen time (default 20:00) | Picks an unsolved problem, preferring weak topics: "Today: 146. LRU Cache (Medium)" → problem |
| LeetCode streak at risk | 21:30 if nothing was solved today | → DSA tab |
| Reflection | 22:00 if not written | → Reflection |
| Weekly digest | Sunday 10:00 | jobs applied, interviews, problems solved, habit streaks |

6. **Skipping reminders when a task is done.** Daily repeating notifications can't be skipped conditionally. Instead:
   - Schedule **one-off** notifications for the next 7 days.
   - Re-plan them on app open, in every worker run, and whenever a habit, problem or reflection is completed (which cancels today's reminder).
7. **Settings › Notifications:**
   - A toggle and a time for each category.
   - Quiet hours (default 22:30–07:30; interviews are exempt).
   - A "Send test notification" button.
   - A **battery optimisation** helper. Many Xiaomi, Oppo, Vivo, Realme and Samsung phones kill background work; the helper opens the right settings page.
8. **Lead scans cost AI calls, so they never run automatically by default.** Add an optional weekly scan, which respects the AI budget (section 5) and uses the Gemini-first chain.
9. **Tests:**
   - pure scheduling functions with a fake clock: next fire time, quiet hours, skipping when done, the 3-per-day cap, deduplication through `NotificationLog`
   - payload-to-route mapping
   - the plugin itself is mocked
   - **On-device check (required):** the test notification, a habit reminder, the worker firing (force it with `adb shell cmd jobscheduler run -f <pkg> <id>`), and a tap opening the right screen.

---

## 4. Components that aren't responsive

### Steps
1. **Automated overflow sweep** (`test/responsive_test.dart`, reusing the seed data in `test_preview/ui_preview_test.dart`):
   - Pump every main screen, detail screen and add/edit form at widths 320, 360, 411, 600 and 840 dp.
   - Use text scales 1.0, 1.3 and 1.6, and both the dark and light themes.
   - The test fails on any `RenderFlex overflowed` exception or `FlutterError`.
2. **Fix the patterns it finds:**
   - Text sitting next to fixed-width boxes: `ats_report_sheet.dart:275` has `SizedBox(width: 84)` and `salary_insights_view.dart:147` has `SizedBox(width: 32)`. Use `Flexible` or `IntrinsicWidth` with `maxLines` and ellipsis.
   - Chip and tag rows should use `Wrap`, never `Row`.
   - Stat grids should use `LayoutBuilder`: 2 columns below 600 dp, 4 columns at 600 dp or more.
   - Long add/edit `AlertDialog`s (add_edit_application 588 lines, add_edit_job 474, add_edit_resume 366, add_edit_client, add_edit_payment, edit_profile) become **scrollable modal bottom sheets**. Add keyboard padding (`MediaQuery.viewInsetsOf`), a sticky Save bar and `SafeArea`.
   - On tablets and foldables, centre the content with a maximum width of 720 dp.
   - Tap targets must be at least 48 dp. Titles get `maxLines: 2` with ellipsis everywhere.
3. **Check:** the sweep test passes. Also check by hand on one small phone (360 dp) with the font size set to Largest.

---

## 5. Too much load on Claude; too few job sources

### What's wrong
- ✅ Every research task goes to Claude Opus with web search:
  - AI job search: `ai_job_search_service.dart:81` runs `research` with up to 8 searches at `medium` effort.
  - Business discovery: `business_discovery_service.dart:168`.
- ✅ `quick()` falls back to Claude whenever Nemotron is missing or fails.
- ✅ Nothing is cached or budgeted, so the same search repeated costs the same again.
- ✅ The job boards are mostly US companies: Airbnb, Stripe, Figma, Reddit and others on Greenhouse; Palantir and Spotify on Lever; Ramp, Linear and Notion on Ashby. That pushes the user towards AI search to find Indian jobs.

### Steps
1. **AI router** (`lib/core/ai/ai_router.dart`): each task has a provider chain with a daily budget, a 24-hour result cache and a circuit breaker.

| Task | Chain (first that works wins) |
|---|---|
| Web job search | **Gemini with Google Search grounding** (`tools: [{google_search: {}}]`) → Claude Sonnet with web search → Claude Opus, only when the user taps **Deep search** |
| Lead discovery | Gemini grounded search to collect candidates → a second Gemini call with `responseSchema` to structure them → the local website inspector (no AI). Claude only for Deep search. |
| Quick drafts (outreach, fit check) | Nemotron → Gemini Flash → Claude Haiku |
| Match verification (on demand, top jobs only) | Gemini Flash → Nemotron |
| Long documents and tailored resumes | Gemini Pro → Claude Sonnet |

2. **Claude settings:**
   - Default to `claude-sonnet-5`. Use `claude-haiku-4-5` for small tasks. Opus is only for Deep search.
   - Web search `max_uses` becomes 3, effort `low`, and `max_tokens` is right-sized.
   - The static system prompts are cached (`cache_control`).
   - Models are chosen in **Settings › AI**.
3. **Budgets and visibility:**
   - Add an `AiUsage` table (provider, task, tokens from the response's `usage`, time).
   - Default daily caps: Claude 10 calls, Gemini 100, Nemotron 200. They are editable.
   - **Settings › AI** shows usage per provider for today and this month.
   - When a cap is hit, the chain moves to the next provider, or the UI says "Daily Claude limit reached, using Gemini".
   - On a 429, respect `retry-after`.
4. **Cache:** an `AiCache` table keyed by `sha256(task + normalised prompt + model)` with a 24-hour TTL. Repeating a search within 24 hours is free.
5. **More free, official job sources**, so AI search isn't needed for coverage:
   - Adzuna (it has an India endpoint; free app id and key)
   - Jooble (free key)
   - Remotive, Arbeitnow, Himalayas and The Muse (public APIs)
   - Follow each API's terms and attribution rules.
   - Replace the US-heavy board list with **India plus remote-friendly companies** on Greenhouse, Lever and Ashby. **Verify each board token returns 200 before adding it**, and drop the ones that 404.
   - Add **Settings › Sources**: turn each source on or off, add a board token, and see each source's last run and counts.
6. **Tests:**
   - The router falls through the chain on error or budget exhaustion.
   - A cache hit makes no HTTP request.
   - The budget resets at local midnight.
   - Each new connector's parsing is tested with recorded JSON fixtures.

---

## 6. Light mode problems (white text on white, and more)

### What's wrong
- ✅ Brand and status colours meant for the dark theme are used directly as **text and icon colours** in the features: 26 × `AppTheme.success`, 15 × `accent`, 15 × `warning`, 15 × `error`, plus `info` and `violet`.
  - On white, `#00D09C` green has a contrast ratio of about 1.9:1 and `#FFB84D` amber about 1.6:1. Both are unreadable.
- ✅ Dark-only tokens are hard-coded: `AppTheme.textMid` in `applications_view.dart:48`, `freelance_screen.dart:20` and `ui_kit.dart:242`.
- ✅ `Colors.white` is used on surfaces that change with the theme, e.g. `habits_tab.dart:181`, `:247` and `:299`.
- ✅ There are 74 raw `Color(0x…)` or `Colors.<name>` uses across 9 files, all tuned for dark: `status_badge.dart`, `priority_chip.dart`, `career_profile_view.dart`, `application_details_screen.dart`, `dsa_problem_details_screen.dart`, `client_details_screen.dart`, `add_edit_resume_dialog.dart`, `add_edit_payment_dialog.dart` and `ui_kit.dart`.
- 🔎 Status-bar icons may not switch between light and dark on screens without an AppBar.

### Steps
1. **Add a `ThemeExtension<AppColors>`** in `app_theme.dart` with separate dark and light values:
   - `success`/`onSuccess`/`successContainer`/`onSuccessContainer`, and the same four for `warning`, `danger`, `info` and `violet`
   - `textMuted`, `cardBorder`, `scoreHigh`, `scoreMid`, `scoreLow`, and a 6-colour `chart` palette

   The light values are darker so they meet contrast rules, e.g. success `#00875F`, warning `#A15C00`, danger `#C4381C`, info `#2F6FDB`.
2. Add a `context.colors` extension. **Replace every direct `AppTheme.<status>`, `Colors.white/black` and `Color(0x…)` in `lib/features` and `lib/shared`** with a token. Tinted backgrounds always pair `xContainer` with `onXContainer`. The only allowed exception is the user-picked habit colour palette.
3. **Guard test** (`test/theme_tokens_test.dart`): grep `lib/features` and `lib/shared` for those patterns and fail if any are found.
4. **Contrast test:** compute the WCAG contrast of every token pair in both themes. Text must be at least 4.5:1; large text and icons at least 3:1.
5. Set `SystemUiOverlayStyle` from the theme (`AppBarTheme.systemOverlayStyle`, plus `AnnotatedRegion` for screens with no AppBar). Check that the navigation bar, chips, `SegmentedButton`, inputs, snackbars, bottom sheets and dialogs use scheme colours.
6. **Check:** golden screenshots of every main screen in **light** and dark at 360×800 (`test_preview`), reviewed by eye. Then a manual pass on a phone with the theme set to Light.

---

## 7. Resume match % is wrong

### What's wrong (`lib/features/career/domain/job_match_service.dart`)
- ✅ **It scores the typed profile fields, not your resume.** It reads `UserProfile.skills`, `preferredRoles` and `currentRole`. If those are empty or stale, the scores are wrong even though a parsed resume exists.
- ✅ **It counts every technology word anywhere in the posting**, including the company blurb and benefits. Required and "nice to have" skills are treated the same. The formula `matched / min(jobTerms, 6)` makes the skills score arbitrary.
- ✅ **The experience check matches the first "N years" in the text**, even something like "10 years of growth".
- ✅ **Free points:**
  - Location gives 10–15 points to almost any job.
  - Any title containing "engineer" or "developer" gets 12 role points.
  - So unrelated jobs still show 25–35%.
- ✅ **The score is recalculated in the UI** (section 1), and screens can disagree.
- ✅ **A better engine already exists but isn't connected.** `career_core`'s engine has a role-family gate, hard filters, and required versus preferred skill scoring.

### Steps
1. **One candidate profile built from the primary resume:**
   - Build a `CandidateProfile` from the primary resume's parsed data (`parsedDataJson`), with your preferences (roles, locations, remote, salary) layered on top.
   - Store a `profileVersion` hash of it. A new version triggers a background re-score (section 1, step 3).
   - If there's no resume, fall back to the profile fields and show "Upload your resume for accurate matches".
2. **Score with `career_core`:**
   - Role family gate: a Sales, HR, Civil or similar job gets tier `NOT_RELEVANT` and is hidden, never "Low match 30%".
   - Required skills count twice as much as preferred ones. Skills are only counted from the requirements sections.
   - The experience requirement comes from the requirements section.
   - Location and salary are soft factors, and they give **no** free points when the role doesn't fit.
   - If a job lists no skills, show **"Not enough data"** instead of a number.
3. **Store and show one number:** `matchScore`, `matchTier` and `matchJson` (a breakdown with matched, missing-required and missing-preferred skills, plus a one-line reason). The list, the details screen, Home and notifications all read the same stored value.
4. **Keep two separate scores on the details screen:**
   - **"Match"**: how well you fit the job.
   - **"ATS score"**: how your resume text reads to a keyword ATS for this job (section 8).

   They answer different questions and must not be mixed.
5. **Optional "Verify with AI" button** on the details screen: Gemini Flash, then Nemotron, gives a second opinion and stores it. Never run this in bulk with Claude.
6. **Delete `job_match_service.dart`** and the in-memory `filterJobs` scoring path.
7. **Tests** (`test/match_accuracy_test.dart` plus the `career_core` corpus):
   - Your resume against a Flutter job scores 80 or more.
   - An unrelated Sales or HR job is `NOT_RELEVANT`.
   - Java ≠ JavaScript, and React ≠ React Native.
   - "Nice to have GraphQL" missing costs only a little; a missing required skill costs a lot.
   - "10 years of growth" is not read as an experience requirement.
   - The same job shows the same score on every screen.
   - Changing the primary resume re-scores all jobs.

---

## 8. Tailored resume per job: LaTeX for Overleaf, or a direct PDF

### Principles
- **No invention.** The resume is only reworded, reordered and focused. No new employers, dates, degrees, metrics or skills.
- **The ≥95% target is measured by the app's own ATS checker.** That checker is transparent: keyword coverage, standard sections and parse-safe formatting, modelled on how common ATSs read resumes.
  - **No tool can guarantee a score inside a company's own ATS** (Workday, Greenhouse, Taleo and others), and the app will say so.
  - If 95% is impossible without skills you don't have, the app shows the highest honest score and lists the gaps.

### Steps
1. **Entry point:** on the job details screen, a **"Tailor my resume"** button opens a sheet. You pick the base resume (primary by default) and the output: **LaTeX**, **PDF** or both.
2. **`lib/features/career/services/resume_tailor_service.dart`:**
   1. **Inputs:** the `CandidateProfile`, the resume text, and the normalised job (title, required and preferred skills, responsibilities).
   2. **Keyword plan (no AI):**
      - Job skills that are evidenced in the resume must appear exactly as the job spells them, e.g. "PostgreSQL", "REST APIs".
      - Job skills that are *not* evidenced become the **gaps list**, which is shown to you and never inserted.
   3. **Rewrite (AI):** Gemini Pro (falling back to Claude Sonnet) with a strict JSON schema, `TailoredResume`: header, summary, skill groups, experience entries (company, role, dates, bullets with `sourceEvidence`), projects, education and certifications.
      - Rules: reorder by relevance, rephrase bullets to use the job's wording where it is truthful, and aim for one page (two if you have more than 8 years of experience).
   4. **Grounding check (no AI):**
      - Every bullet's `sourceEvidence` must match the original resume, with token overlap of at least 0.6, or the bullet is dropped.
      - Every number, company, date and degree in the output must exist in the source.
   5. **ATS check and loop:** extend `ats_scoring_service.dart` so it scores:
      - weighted keyword coverage of the required and preferred skills
      - the standard section headings
      - contact details
      - date consistency
      - bullet quality (action verbs, measurable results)
      - length
      - parse-safe formatting

      If the score is below 95 and evidenced keywords are still missing, send the missing list back for up to 2 more rewrites. Then show the score, the checklist, and any gaps you can't close.
3. **LaTeX output:**
   - A **template rendered in Dart**; the AI never writes the LaTeX.
   - The template is ATS-safe: single column, `article` class, `geometry`, `enumitem`, `titlesec` and `hyperref`. It has no tables, columns, icons or graphics, and includes `\pdfgentounicode=1` with `glyphtounicode` so the text can be extracted.
   - A LaTeX escaper handles `& % $ # _ { } ~ ^ \`.
   - Actions:
     - **Copy LaTeX**
     - **Share .tex**
     - **Open in Overleaf**: `https://www.overleaf.com/docs?encoded_snip=<url-encoded tex>` through `url_launcher`. If the URL is too long, fall back to copying the text and opening Overleaf's new-project page.
4. **Direct PDF output:**
   - The same `TailoredResume` is rendered with the `pdf` package on the phone, in an isolate. It is single column with real selectable text and standard fonts.
   - Saved to Documents with Open and Share actions.
   - **Round-trip check:** run the app's own PDF text extractor on the new PDF and ATS-score the extracted text. It must be within 2 points of the pre-render score, which proves the file is parseable.
5. **Save it:** store the result as a new resume, "Tailored – {Company} – {Role}", linked to the job, with its LaTeX, PDF path and ATS score (v11 columns on `Resumes`: `jobId`, `latexSource`, `atsScore`). When you mark the job as applied, it is set as `resumeUsed` automatically.
6. **Tests:**
   - LaTeX escaping
   - the template contains no forbidden packages or constructs
   - the grounding check drops an invented bullet and an invented metric
   - ATS scorer cases
   - the round-trip PDF score
   - the gaps are never inserted into the output

   If `pdflatex` or `tectonic` is installed on the dev machine, compile the fixture `.tex` in a test that is skipped when neither is available, and report whether it ran.

---

## 9. Improve the UI further (Groww style, less ugly)

1. **Design tokens:**
   - spacing 4/8/12/16/24/32
   - corner radius 12/16/20
   - one type scale
   - `FontFeature.tabularFigures()` for every number (scores, salaries, counts)
2. **Home:**
   - A hero card: "N new matches today", with the best match inline.
   - A horizontal "Your day" strip: habits, today's LeetCode problem, follow-ups due.
   - Then top matches, then top leads.
   - Remove duplicate stat tiles.
3. **Job card:**
   - a colour-seeded company initial avatar, title, company and location
   - a **match ring** in the tier colour
   - salary in your currency
   - a freshness chip (NEW / UPDATED)
   - up to 3 matched-skill chips and 1 missing chip
   - swipe to save or dismiss
4. **Job details:**
   - a sticky bottom bar with **Apply** and **Tailor resume**
   - a match breakdown bar
   - a collapsible description
5. **Track:**
   - a GitHub-style habit heatmap
   - a LeetCode progress ring by difficulty
   - a "problem of the day" card
6. **Everywhere:**
   - shimmer skeletons instead of spinners
   - one-action empty states
   - bottom sheets instead of dialogs
   - short 150–250 ms fades, a Hero transition from job card to details, and light haptics on save and complete
7. **Declutter pass:** list every button on every screen in `docs/UI_AUDIT.md`. Remove anything that duplicates another control or does nothing. Keep one primary action per screen.
8. **Review loop:** render goldens (`test_preview`) for every main screen in dark and light at 360×800, before and after, and review them. Iterate until nothing overflows, clips or has poor contrast.

---

## 10. App name and logo: "Risheesh"

### What's there now
- ✅ The launcher label is `android:label="Career OS"` in `AndroidManifest.xml:6`.
- ✅ `AppConstants.appName` is `'Risheesh OS'`.
- ✅ Other places still say "Career OS":
  - `onboarding_screen.dart:181` (title text)
  - `document_service.dart:80` (PDF author)
  - `server_connection_screen.dart:79` and `:192`
  - the `CareerOSApp` class name
  - the logger tag `'CareerOS'`
- ✅ The icon is the default Flutter `@mipmap/ic_launcher`. The project has no branding assets and no `flutter_launcher_icons` or splash setup.

### Steps
1. **Name the app "Risheesh" everywhere the user sees it:**
   - `android:label="Risheesh"`
   - `AppConstants.appName = 'Risheesh'`, which is used by `MaterialApp.title`, onboarding, Settings › About, the AI keys screen, the PDF/DOCX author and the notification channel group name
   - `web/index.html` `<title>` and `web/manifest.json` `name` and `short_name`
   - the window title in `windows/runner/main.cpp` and the `ProductName`/`FileDescription` in `windows/runner/Runner.rc`
   - Rename `CareerOSApp` to `RisheeshApp` and the logger tag to `'Risheesh'`.
   - Replace every "Career OS" string in the UI with `AppConstants.appName`, and add a test that greps `lib/` for `Career OS` and fails if it finds one.
   - **Do not change** `applicationId`/`namespace` (`com.risheesh.career_os`) or the Dart package name `career_os`. Changing the id would install as a separate app and lose the user's local database and keys.
2. **Logo design:** a Groww-style mark that matches the app theme.
   - A rounded-square tile with a green gradient (`#00D09C` → `#00B386`).
   - A bold white geometric **"R"** whose leg ends in a small upward arrow, meaning career growth.
   - It must stay legible at 24 px, so no thin strokes and no text other than the R.
   - Source files:
     - `assets/branding/logo.svg`: a hand-written vector, the master copy
     - `logo_1024.png`: the full tile
     - `logo_foreground.png`: 1024×1024, only the R and arrow, kept inside the central 66% safe zone for adaptive-icon masks
     - `logo_monochrome.png`: a single-colour silhouette for Android 13+ themed icons
   - **If the user supplies their own logo** (a PNG or SVG of at least 1024×1024 at `assets/branding/logo_source.*`), use it instead and derive the variants from it.
3. **Launcher icons:** add `flutter_launcher_icons` as a dev dependency with this config in `pubspec.yaml`:
   - `image_path: assets/branding/logo_1024.png`
   - `adaptive_icon_foreground: assets/branding/logo_foreground.png`
   - `adaptive_icon_background: "#00B386"`
   - `adaptive_icon_monochrome: assets/branding/logo_monochrome.png`
   - `min_sdk_android: 21`
   - `web` and `windows` generation turned on

   Run `dart run flutter_launcher_icons`.
4. **Notification small icon** (needed by section 3): Android draws notification icons as white silhouettes, so a colour icon shows up as a white square.
   - Add `android/app/src/main/res/drawable/ic_stat_risheesh.xml`, a vector drawable of the R and arrow, white on transparent.
   - Use it as the default icon in the notification service, with `color: #00D09C`.
5. **Splash screen:** add `flutter_native_splash` as a dev dependency.
   - Background `#121212` in dark mode and `#FFFFFF` in light mode, with the centred logo.
   - Configure the `android_12` section (`icon_background_color`) so Android 12+ shows the same brand splash instead of a blank screen.
   - Run `dart run flutter_native_splash:create`.
6. **In-app logo:** add an `AppLogo({double size})` widget in `ui_kit.dart` that shows `logo_1024.png` through `Image.asset` (no SVG dependency needed). Use it:
   - on the onboarding welcome screen
   - on the AI keys first-run screen
   - on Settings › About
   - as a small mark in the header of generated PDFs

   Register `assets/branding/` under `flutter: assets:`.
7. **Checks:**
   - `aapt dump badging build/app/outputs/flutter-apk/app-release.apk` shows `application-label:'Risheesh'` and the icon paths.
   - A widget test finds "Risheesh" on the onboarding screen.
   - The grep test finds no "Career OS".
   - **On a phone:** the launcher shows "Risheesh" with the new icon in round and squircle masks, themed icons (Android 13+) show the monochrome version, the notification icon is a clean white "R", and the splash shows in both dark and light mode.

---

## 11. Schema v11 summary (one migration)

- **`Jobs`:** matchScore, matchTier, matchJson, matchProfileVersion, roleFamily, isRemote, salaryMinInr, salaryMaxInr. `rawJson` is no longer written; it is cleared once, then the database is vacuumed.
- **`UserProfiles`:** expectedSalaryAmount, expectedSalaryCurrency, expectedSalaryPeriod, displayCurrency.
- **`Habits`:** reminderTime. **`DSA` settings:** dailyProblemTime, which can live in prefs.
- **`Resumes`:** jobId, latexSource, atsScore.
- **New tables:** `FxRates`, `NotificationLog`, `AiUsage`, `AiCache`.
- **`test/migration_v11_test.dart`:** start from a v10 database with jobs, applications, a free-text salary and habits, and assert that nothing is lost and the defaults are filled in.

---

## 12. Order of work

| Phase | Items | Why this order |
|---|---|---|
| P0 | 10. App name "Risheesh", logo, launcher icons, notification icon, splash | Quick, and P3 needs the white notification icon |
| P1 | 1. Crash capture, scoring out of `build()`, paging, database diet, v11 migration | Stops the crashes and slowness; everything else builds on the stored scores |
| P2 | 7. Resume match on `career_core` | Correct numbers are needed by the feed, notifications and tailoring |
| P3 | 3 and 9. Notifications and the background worker | Depends on stored scores to notify only good matches |
| P4 | 6. Light mode tokens, then 4. responsive sweep | Mechanical, and the guard tests prevent regressions |
| P5 | 5. AI router, budgets, cache and new sources | Reduces Claude use before new AI features are added |
| P6 | 2. Salary and currency | Uses the new sources' salary data |
| P7 | 8. Tailored resume (LaTeX and PDF) | Uses the router, ATS scorer and profile |
| P8 | 10. UI polish and declutter, goldens | Last, on top of stable screens |
| P9 | Release APK, full test run, device checklist, report | |

---

## 13. Definition of done

**Commands, all green:**
- `flutter analyze` reports "No issues found!"
- `flutter test`
- `(cd packages/career_core && dart test)`
- `flutter build apk --release`

Report the APK size.

**Device checklist.** Each item is marked done or "not verified", with the reason:
- no ANR while opening Jobs and refreshing with at least 1,000 jobs
- a test notification arrives
- a habit reminder arrives and is skipped once the habit is done
- the background worker produces a job notification
- tapping a notification opens the right screen
- light mode has no unreadable text
- a 360 dp phone at the Largest font size shows no overflow
- the tailored PDF opens, and Overleaf opens the `.tex`
- the launcher shows "Risheesh" with the new adaptive and themed icon
- the splash screen shows the logo
- the notification icon is a clean white "R"

**Report:** what changed per item, files added, modified and removed, the schema changes, the model and provider per task, and anything still unverified.
