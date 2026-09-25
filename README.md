# Career OS 🚀

> **The Offline-First Personal Career, Work, Freelance & Life Operating System**

[![Flutter Version](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Database](https://img.shields.io/badge/SQLite-Drift%20ORM-003B57?logo=sqlite)](https://drift.simonbinder.eu/)
[![State Management](https://img.shields.io/badge/State-Riverpod%202.0-blue)](https://riverpod.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Offline--First%20%7C%20Zero--Telemetry-green)](#privacy--data-governance)
[![Release](https://img.shields.io/badge/Release-v1.0.0-success)](#release-builds)

---

## 📖 Overview

**Career OS** is an all-in-one, offline-first personal career productivity hub designed for software engineers, freelancers, and technical professionals. It consolidates job hunt pipelines, daily software engineering tasks, freelance client management, DSA interview revision, skill progression, workouts, and personal finance into a unified, secure, local database.

---

## 🛡️ Privacy & Core Architectural Principles

1. **100% Offline-First**: All data is stored on-device in a high-performance **SQLite** database managed via **Drift ORM**.
2. **Zero Telemetry**: No tracking cookies, no Google Analytics, no Firebase Crashlytics telemetry, and no ad SDKs.
3. **Local AI (Ollama)**: The AI copilot connects to your own local or LAN-hosted **Ollama** server (`http://127.0.0.1:11434`), ensuring your work notes, resumes, and financials are never sent to proprietary cloud LLMs.
4. **Proactive Automation with User Consent**: Background evaluators detect approaching deadlines, follow-ups, and duplicate postings, but **never mutate your data without explicit confirmation**.

---

## 🧩 Core Modules & Features

### 💼 1. Career Module
- **Job Tracker**: Discover, catalog, bookmark, and evaluate job opportunities with salary ranges, skills match, and notes.
- **Application Pipeline**: KanBan-style stage tracking (`Wishlist` ➔ `Applied` ➔ `Screening` ➔ `Interview` ➔ `Offer` ➔ `Rejected` ➔ `Archived`) with automated follow-up dates and salary tracking.
- **Resume Vault**: Store and manage multiple tailored resumes (file paths, markdown contents, tags, primary resume switch).
- **Match Scoring Engine**: Transparent match percentage calculation between job descriptions and your stored career skills.
- **Saved Searches**: Configurable automated search queries with frequency and location filters.

### 💻 2. Work & Engineering Module
- **Task Management**: Structured task tracking with categories (`FEATURE`, `BUG`, `REFACTOR`, `DOCS`, `MEETING`, `OTHER`), priorities, estimated vs. actual hours, and project associations.
- **Project Hub**: Manage multi-faceted engineering projects with deadlines, repository URLs, documentation links, and progress metrics.
- **EOD Standup Synthesizer**: Daily standup updates with completed items, in-progress tasks, and blockers.
- **Things to Ask / Blockers Tracker**: Dedicated workspace blocker resolution board.
- **Meeting & Work Notes**: Fast technical note-taking with markdown support.

### 🤝 3. Freelance CRM
- **Lead Pipeline**: Track potential consulting and contract opportunities across stages (`Prospect` ➔ `Contacted` ➔ `Proposal Sent` ➔ `Negotiation` ➔ `Won` ➔ `Lost`).
- **Client CRM**: Maintain client contacts, company names, billing emails, websites, notes, and active status.
- **Lead Conversion**: Convert won leads directly into active projects and client records.
- **Milestone & Revenue Engine**: Track fixed-price and hourly milestone payments, received revenue, pending payouts, and payment dates.

### 📊 4. Tracking Hub (DSA, Learning, Fitness, Finance)
- **DSA Problem Tracker**: Catalog LeetCode/HackerRank problems by topic, difficulty, spaced repetition dates, attempt count, solution notes, and status.
- **Learning & Skills Hub**: Track target technologies, mastery percentages, and attach study resources (courses, books, videos, docs).
- **Fitness Tracker**: Log daily body weights and structured workouts with exercise sets, reps, and weights.
- **Finance Engine**: Track categorized incomes and expenses with monthly net savings calculations and CSV export capabilities.

### 🤖 5. Local AI Copilot & Automation Engine
- **Ollama Integration**: Fully configurable host, port, model selection, temperature, and timeout.
- **Dynamic Structured Context Builder**: Injects real on-device tasks, DSA problems, applications, and finances into prompts with anti-prompt-injection delimiter tagging.
- **Structured Action Parser**: Extracts actionable commands (`CREATE_TASK`, `SET_DSA_REVISION_DATE`, `CREATE_EXPENSE`, `LOG_WORKOUT`) with mandatory confirmation modals.
- **Automation Scheduler**: Evaluates deadline triggers, follow-up alerts, public RSS feed job discoveries, and weekly digest aggregation.

---

## 🛠️ Technology Stack

| Layer | Technology |
| :--- | :--- |
| **Framework** | Flutter 3.x (Channels: Stable) |
| **Language** | Dart 3.x with strict null-safety |
| **State Management** | Riverpod 2.x (StateNotifier & StreamProviders) |
| **Database Engine** | SQLite via Drift ORM (Schema v8 + Composite Indexing) |
| **Routing** | GoRouter 14.x with `StatefulShellRoute.indexedStack` |
| **UI Design** | Material 3 Expressive Design System (Light & Dark themes) |
| **Testing** | Flutter Test framework (Unit, integration, and database tests) |

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.24.0 or higher)
- [Java Development Kit](https://adoptium.net/) (JDK 17)
- Android SDK with Platform 34+

### Clone & Install
```bash
git clone https://github.com/rishi-bhardvaj/Risheesh.git
cd Risheesh

# Install dependencies
flutter pub get
```

### Run in Debug Mode
```bash
flutter run
```

### Run Full Test Suite
```bash
flutter test --no-pub
```

### Build Production Release APK
```bash
flutter build apk --release
```
The optimized release APK will be generated at:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 🤖 Ollama Local AI Setup

To leverage the AI features without sending data to third parties:

1. Install [Ollama](https://ollama.com/) on your host machine.
2. Pull your preferred model:
   ```bash
   ollama pull llama3:8b
   # or
   ollama pull mistral:7b
   # or
   ollama pull qwen2.5-coder:7b
   ```
3. Start the Ollama server:
   ```bash
   ollama serve
   ```
4. In **Career OS**:
   - Open **Personal AI** ➔ **Settings** (or through main Settings).
   - Enter your host:
     - Android Emulator: `http://10.0.2.2:11434`
     - Physical Device on LAN: `http://<YOUR_PC_LAN_IP>:11434`
     - Desktop / Web: `http://127.0.0.1:11434`
   - Test connection and select your downloaded model.

---

## 🗄️ Database Architecture & Migrations

Career OS uses **Drift ORM** on top of SQLite with non-destructive migrations (currently Schema Version 8) spanning 32 tables.

### Key Composite Indexes
- `jobs(company, discovered_at)`
- `job_applications(status, interview_date)`
- `tasks(status, project_id, due_date)`
- `d_s_a_problems(topic, difficulty, revision_date)`
- `freelance_leads(status)`
- `freelance_payments(payment_date)`
- `incomes(date)` & `expenses(date)`
- `body_weights(date)`

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
Open source package licenses can be viewed natively inside the app under **Settings ➔ About Career OS ➔ Open Source Licenses**.
