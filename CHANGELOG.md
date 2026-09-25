# Changelog

All notable changes to the **Career OS** project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-09-25

### 🚀 Production Release: Personal Career & Work Operating System

#### 💼 Career Module
- Full-featured Job Board with company, role, salary range, job URL, notes, and bookmarking.
- KanBan Job Application tracker spanning stages: `Wishlist`, `Applied`, `Screening`, `Interview`, `Offer`, `Rejected`, and `Archived`.
- Resume Vault with support for multiple tailored resumes, metadata tags, and primary resume defaults.
- Transparent algorithmic Job Match Scoring comparing job skill requirements against stored user skills.
- Automated Saved Searches with interval configuration and location filtering.

#### 💻 Work & Engineering Module
- Task Tracker supporting categories (`FEATURE`, `BUG`, `REFACTOR`, `DOCS`, `MEETING`, `OTHER`), priorities (`LOW`, `MEDIUM`, `HIGH`, `URGENT`), and estimated vs. actual hours.
- Engineering Project Hub with repository links, documentation references, and progress calculation.
- EOD Standup Synthesizer for generating clean daily progress reports and blocker summaries.
- Dedicated "Things to Ask" blocker tracking board with quick resolution toggles.
- Technical & Meeting Notes notebook with markdown formatting.

#### 🤝 Freelance CRM
- Lead Management Pipeline (`Prospect`, `Contacted`, `Proposal Sent`, `Negotiation`, `Won`, `Lost`).
- Client Directory with point-of-contact details, billing emails, and status toggles.
- Instant Lead conversion into Clients and active Freelance Projects.
- Milestone Payments Tracker with paid/pending status, currencies, and revenue aggregation.

#### 📊 Tracking Hub
- DSA Tracker with topic categorization, difficulty rating, attempt counter, and spaced revision scheduling.
- Learning & Skills Progression with percentage mastery and linked study resources.
- Fitness Tracker with daily body weight tracking and custom multi-set workout logs.
- Personal Finance Module with income/expense logging, monthly net savings calculation, and CSV exports.

#### 🤖 Local AI & Automation
- Direct local integration with Ollama instances (`http://127.0.0.1:11434`) with zero cloud telemetry.
- Dynamic Structured Context Builder with anti-prompt-injection delimiter protection.
- Structured Action Parser proposing actions (`CREATE_TASK`, `SET_DSA_REVISION_DATE`, `CREATE_EXPENSE`, `LOG_WORKOUT`) with mandatory confirmation dialogs.
- Proactive Automation Engine with scheduled evaluation of deadlines, follow-ups, and RSS feed job discovery.
- Local notification alerts with user-configured quiet hours and categories.
- Weekly Digest Aggregator summarizing cross-module productivity.

#### 🛡️ Security, Performance & Release Hardening
- 100% Offline-First architecture backed by on-device SQLite via Drift ORM (Schema v8).
- Composite SQL indexing on high-frequency query fields for 60fps scrolling and instant search.
- Sanitized `AppLogger` utility preventing sensitive credential leaks.
- Zero analytics, advertising, or background telemetry SDKs.
- Material 3 design system with seamless dynamic Dark and Light theme switching.
- Comprehensive unit, integration, and database test suites (100% passing).
- Clean Android Manifest with scoped permissions (`INTERNET`, `POST_NOTIFICATIONS`) and Java 17 compatibility.
