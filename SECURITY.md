# Security Policy & Hardening Documentation

## 🔒 Cusatify Security Posture

This repository has undergone a comprehensive DevSecOps security hardening overhaul.

---

### 1. Secret Management
- **No Hardcoded Secrets**: All backend API keys, Supabase URLs, and JWT tokens have been migrated out of source code.
- **Environment Configuration**: Environment variables are dynamically loaded via `flutter_dotenv` at runtime or injected via `--dart-define` flags during build/CI.
- **Git Protection**: `.env` and sensitive environment patterns are strictly ignored by `.gitignore`. A sanitized template `.env.example` is provided for local development.

### 2. API & Network Hardening
- **Client Rate Limiting**: Built-in `SecurityRateLimiter` middleware protects sensitive endpoints (login, registration, attendance submissions, and event creation) against brute-force attacks and DDoS.
- **Client Security Headers**: Standardized security headers (`x-client-info`, connection pool limits, retry limits) applied to database communication.
- **Safe Error Handling**: `SecurityConfig.getSafeErrorMessage` prevents internal error details, stack traces, and database connection strings from leaking to end users.

### 3. Database Security & Role-Based Access Control (RBAC)
- **PostgreSQL Row Level Security (RLS)**: Strict RLS policies enabled across all tables in `supabase/schema_and_policies.sql`.
- **User-Scoped Queries**: All queries for user-owned resources (`notes`, `library_logs`, `profile-photos`) enforce `auth.uid() = user_uid` at both the database and application layers.
- **Role Scoping**: Attendance marking, event creation, notice announcements, and assignment creation are strictly restricted to authenticated Faculty roles.

### 4. Input Sanitization & Validation
- **XSS & Injection Protection**: `InputSanitizer` cleans incoming user input, strips HTML/script tags, removes control characters, and enforces length constraints.
- **Strict Format Validation**: RFC 5322 email regex normalization and alphanumeric constraints on student and faculty IDs.
- **Password Strength**: Minimum password complexity requirements enforced across all registration flows.

### 5. Continuous Security (CI/CD)
- **Automated Scanning Workflow** (`.github/workflows/security-scan.yml`):
  - **Secret Detection**: Gitleaks scanner running on all PRs and pushes to `main`.
  - **Static Application Security Testing (SAST)**: Flutter and Dart static analyzer.
  - **Vulnerability Scanning**: Google OSV-Scanner and Aquasecurity Trivy dependency CVE audits.

---

## 🛠️ Reporting a Vulnerability

If you discover a security vulnerability within Cusatify, please do NOT create a public issue. Instead, report it privately to the maintainers or via GitHub Security Advisories.
