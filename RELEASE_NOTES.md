# Release notes — v1.0.0

## Claims

This version claims the **assessment builder critical path** is trustworthy for client use:

- Create assessment → list → show continuity (id + name + time limit)
- Add taxonomy and custom skills with persisted re-read
- Selective nested skill remove via `_destroy` (API + web edit)
- Quality net: Definition-of-Ready PR gate, API e2e (TC-E2E-001…008), web payload unit tests, lint

## Included in this release

- Ranked audit of assessments+skills risks (`assessment/01-audit.md`)
- Quality system docs and CI (`assessment/02-quality-system.md`, `.github/workflows/quality.yml`)
- Fixes for web taxonomy `skill_id` / `scope_exclude` drop and edit-remove without `_destroy`
- Seeded local admin `admin@test-corp.example` for assessor flows
- Release-gated CI on `v*` tags (`.github/workflows/release.yml`)

## Not claimed

- Portfolio / fit-gap / interview session correctness
- Multi-tenant fail-closed hardening
- Signup / login UI completeness
- `system_prompt_generated` meaning true generation success (still means “job enqueued”)
