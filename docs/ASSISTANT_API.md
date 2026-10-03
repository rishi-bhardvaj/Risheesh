# Dedicated Read-Only Assistant API

Secure, read-only HTTP API namespace (`/api/v1/assistant/*`) designed for personal assistants, ChatGPT routines, and automated daily career briefings.

---

## 1. Architecture

```text
External Job / Freelance Sources
               ↓
Hourly Sync (GitHub Actions / Scheduler)
               ↓
Render Node.js / TypeScript Backend
               ↓
Neon PostgreSQL (Source of Truth)
               ↓
Dedicated Read-Only Assistant API (/api/v1/assistant/*)
      [Authorization: Bearer <ASSISTANT_API_KEY>]
               ↓
ChatGPT Routine / Custom GPT / Automation
               ↓
Daily Digest / Opportunities / Action Items
```

### Security Guarantees
- **Strictly Read-Only**: The assistant namespace only exposes `GET` endpoints. Zero write, update, or delete endpoints exist.
- **Independent Secret**: Authenticated via `ASSISTANT_API_KEY`. Completely decoupled from `JOB_SYNC_SECRET` and `IMPORT_API_KEY`.
- **Zero Database Exposure**: External assistants never access PostgreSQL or connection strings directly.
- **Fail-Closed**: If `ASSISTANT_API_KEY` is not set on the server, all endpoints answer with `503 ASSISTANT_NOT_CONFIGURED`.
- **Data Sanitization**: Internal bookkeeping fields (e.g. `raw_data`, internal auth hashes, private recruiter contacts, internal resume IDs) are stripped before returning responses.
- **Constant-Time Comparison**: Header comparison uses cryptographic SHA-256 digests in constant time to prevent timing side-channels.
- **Brute-Force Rate Limiting**: In-memory limiter blocks repeat offenders (20 failed attempts in 15 minutes per IP).

---

## 2. Endpoints

All endpoints require:
```http
Authorization: Bearer <ASSISTANT_API_KEY>
```

### 1. `GET /api/v1/assistant/health`
Verifies authentication and database connectivity.

**Example Request:**
```bash
curl -H "Authorization: Bearer $ASSISTANT_API_KEY" \
  https://YOUR-BACKEND.onrender.com/api/v1/assistant/health
```

**Example Response:**
```json
{
  "success": true,
  "generatedAt": "2026-10-03T10:00:00.000Z",
  "status": "ok",
  "database": "connected",
  "access": "read_only"
}
```

---

### 2. `GET /api/v1/assistant/summary`
Calculates real aggregate metrics across jobs, freelance opportunities, and applications for a given time window.

**Query Parameters:**
| Parameter | Type | Default | Description |
|---|---|---|---|
| `since` | string | `24h` | Relative duration (`24h`, `7d`, `30d`) or ISO date |
| `until` | string | (now) | End date of window |

**Example Request:**
```bash
curl -H "Authorization: Bearer $ASSISTANT_API_KEY" \
  "https://YOUR-BACKEND.onrender.com/api/v1/assistant/summary?since=24h"
```

**Example Response:**
```json
{
  "success": true,
  "generatedAt": "2026-10-03T10:00:00.000Z",
  "period": {
    "from": "2026-10-02T10:00:00.000Z",
    "to": "2026-10-03T10:00:00.000Z"
  },
  "jobs": {
    "new": 14,
    "open": 182,
    "highMatch": 23,
    "saved": 5
  },
  "freelance": {
    "new": 4,
    "open": 19,
    "highMatch": 6
  },
  "applications": {
    "submitted": 2,
    "pending": 8,
    "needsFollowUp": 3,
    "responses": 1
  }
}
```

---

### 3. `GET /api/v1/assistant/jobs`
Fetches sanitized active job postings, prioritized by match score.

**Query Parameters:**
| Parameter | Type | Default | Description |
|---|---|---|---|
| `since` | string | - | Duration (e.g. `24h`, `7d`) or ISO date (`posted_date` / `discovered_at`) |
| `limit` | number | `25` | Maximum items to return (max `100`) |
| `page` | number | `1` | Page number |
| `status` | string | `OPEN` | `OPEN`, `STALE`, `CLOSED`, or `ALL` |
| `min_score`| number | - | Minimum relevance score (0–100) |
| `remote` | string | - | `'true'` or `'false'` |
| `location`| string | - | Filter by location |
| `source` | string | - | Filter by ATS provider (greenhouse, lever, ashby, etc.) |
| `search` | string | - | Free-text search in title, company, description, skills |

**Example Request:**
```bash
curl -H "Authorization: Bearer $ASSISTANT_API_KEY" \
  "https://YOUR-BACKEND.onrender.com/api/v1/assistant/jobs?since=24h&min_score=80&limit=25"
```

**Example Item:**
```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "externalId": "stripe:5678",
  "title": "Software Engineer, Backend",
  "company": "Stripe",
  "location": "Bengaluru, India",
  "remote": false,
  "employmentType": "Full-time",
  "experienceRequirement": "0-2 years",
  "salary": null,
  "source": "Greenhouse",
  "url": "https://boards.greenhouse.io/stripe/jobs/5678",
  "postedDate": "2026-10-03T08:15:00.000Z",
  "discoveredAt": "2026-10-03T08:17:00.000Z",
  "matchScore": 94,
  "matchReason": "Strong Java, Spring Boot, and REST API match",
  "skills": ["Java", "Spring Boot", "PostgreSQL"],
  "status": "OPEN"
}
```

---

### 4. `GET /api/v1/assistant/freelance`
Fetches sanitized freelance leads without exposing confidential contact notes or raw payloads.

**Query Parameters:**
| Parameter | Type | Default | Description |
|---|---|---|---|
| `since` | string | - | Duration or ISO date for lead creation |
| `limit` | number | `25` | Maximum items (max `100`) |
| `page` | number | `1` | Page number |
| `status` | string | - | Lead status (e.g. `NEW_LEAD`, `PROPOSAL_SENT`) |
| `platform` | string | - | Platform (Upwork, Freelancer, Direct, etc.) |
| `min_score`| number | - | Minimum match score (0–100) |
| `search` | string | - | Free-text search |

**Example Request:**
```bash
curl -H "Authorization: Bearer $ASSISTANT_API_KEY" \
  "https://YOUR-BACKEND.onrender.com/api/v1/assistant/freelance?since=48h&min_score=75"
```

---

### 5. `GET /api/v1/assistant/applications`
Fetches active job applications and follow-ups.

**Query Parameters:**
| Parameter | Type | Default | Description |
|---|---|---|---|
| `since` | string | - | Filter by application date |
| `status` | string | - | Filter by status (`applied`, `interviewing`, `rejected`, etc.) |
| `limit` | number | `50` | Maximum items (max `100`) |
| `page` | number | `1` | Page number |

**Example Item:**
```json
{
  "id": "789e0123-e89b-12d3-a456-426614174001",
  "jobId": "123e4567-e89b-12d3-a456-426614174000",
  "company": "Stripe",
  "role": "Software Engineer, Backend",
  "status": "interviewing",
  "appliedAt": "2026-09-28T14:30:00.000Z",
  "followUpDate": "2026-10-04T09:00:00.000Z",
  "interviewDate": "2026-10-05T15:00:00.000Z",
  "interviewStage": "Technical Round 1",
  "recruiterName": "Jane Doe",
  "nextAction": "Prepare Spring Security & system design notes",
  "notes": "Passed initial HR screening on Oct 1"
}
```

---

## 3. PowerShell Verification

You can test these endpoints from Windows PowerShell:

```powershell
$headers = @{
  Authorization = "Bearer $env:ASSISTANT_API_KEY"
}

# 1. Check health
Invoke-RestMethod -Uri "https://risheesh-backend.onrender.com/api/v1/assistant/health" -Headers $headers -Method Get

# 2. Check 24-hour summary
Invoke-RestMethod -Uri "https://risheesh-backend.onrender.com/api/v1/assistant/summary?since=24h" -Headers $headers -Method Get

# 3. Check high-match jobs
Invoke-RestMethod -Uri "https://risheesh-backend.onrender.com/api/v1/assistant/jobs?since=24h&min_score=80" -Headers $headers -Method Get
```
