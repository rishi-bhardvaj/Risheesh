# Career OS: Platform Automation & Ingestion Policy

**Date of Review:** 2026-09-29  
**Specification Reference:** Section 5 (Platform Policy)

---

## 1. Compliance Principles
Career OS strictly adheres to terms of service, platform agreements, and ethical automation principles:
- **No CAPTCHA Bypassing:** The system will never attempt to evade, solve, or circumvent CAPTCHAs or Cloudflare bot checks.
- **No Login / Credential Scraping:** The system never uses harvested cookies, session storage, or auth tokens.
- **No Rate-Limit Evasion:** Every connector enforces explicit minimum request intervals and per-minute request ceilings.
- **Assisted Mode Over Prohibited Automation:** Where a platform prohibits robotic modification of profiles or automated DOM extraction, Career OS ships an assisted workflow (reminders, one-click copy, direct deep link).

---

## 2. Platform Capability Matrix

| Platform | Automated DOM Extraction | Auto Page Refresh | User Capture | Profile Automation | Official Route |
|---|---|---|---|---|---|
| **LinkedIn** | **OFF** (User Agreement Sec 8.2 prohibits bots/plugins) | **OFF** | **ON** (Selected text or URL link only via browser extension) | **UNSUPPORTED** (Ship assisted notification with copy & deep link) | Resolve to official company ATS (Greenhouse, Lever, Ashby, Workable, SmartRecruiters) or careers-page JSON-LD. |
| **Naukri** | **OFF** (Terms prohibit scraping/unauthorized bots) | **OFF** | **ON** (Selected text or URL link only) | **UNSUPPORTED** (Assisted reminder mode) | Resolve to official company ATS or careers-page JSON-LD. |
| **Greenhouse** | N/A (Server queries official public JSON API) | N/A (Scheduled server poll) | Allowed | N/A | Public Greenhouse Board API (`boards-api.greenhouse.io`). |
| **Lever** | N/A (Server queries official public JSON API) | N/A (Scheduled server poll) | Allowed | N/A | Public Lever Postings API (`api.lever.co/v0/postings`). |
| **Ashby** | N/A (Server queries official public JSON API) | N/A (Scheduled server poll) | Allowed | N/A | Public Ashby API (`jobs.ashbyhq.com/api/non-user-graphql`). |
| **RemoteOK** | N/A (Public REST API) | N/A (Server poll with User-Agent) | Allowed | N/A | Public API (`remoteok.com/api`). |
| **WeWorkRemotely** | N/A (Public RSS feed) | N/A (Server poll) | Allowed | N/A | Public RSS (`weworkremotely.com/categories/...rss`). |
| **JSON-LD Pages** | **ON** (`script[type="application/ld+json"]` JobPosting only) | User-allowlisted domains only | Allowed | N/A | Schema.org JobPosting structured data. |
