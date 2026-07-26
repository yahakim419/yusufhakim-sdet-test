# Release decision — v1.0.0

## Recommendation

**Ship (releasable)** for the assessment + skills builder path, with the accepted risks below.

## What the gate checked

| Gate | Result |
|------|--------|
| Lint (API RuboCop, web ESLint/tsc) | Required green on `main` / tag |
| API e2e business-flow (TC-E2E-001…008) | Required green — create/list/show/skill add+selective destroy |
| Web assessment payload unit tests | Required green — taxonomy identity + `_destroy` |
| DoR PR gate | Enforced on pull requests |
| Tag workflow `release.yml` | Runs lint + e2e + web tests; surfaces **RELEASABLE** / fails job if not |

Human review artifacts: `assessment/01-audit.md`, `assessment/02-quality-system.md`, this file, `RELEASE_NOTES.md`.

## What it found

- Prior P0s (web edit remove without `_destroy`; taxonomy pick dropping `skill_id`) are **fixed** and covered by automated checks.
- API nested-attributes path for selective destroy was already correct; web is now aligned.
- Remaining items are conscious accepts from the audit, not silent oversights.

## Accepted risks (named owner)

| Risk | Severity | Owner | Mitigation |
|------|----------|-------|------------|
| Create 201 body omits `skills` key used by show | P1 | Platform API owner | Clients re-GET; e2e always re-reads |
| `system_prompt_generated: true` = enqueue, not generate | P1 | Platform API owner | Monitor Sidekiq; follow-up to rename or poll prompt |
| Tenant fail-open if middleware leaves tenant unset | P2 | Platform security | Happy-path JWT+scheme used by assessor UI; harden later |
| Login/signup UI seams | P3 | Out of scope this release | Documented in audit; not in claim |

## If gate goes red

Any open **P0** on skill continuity → **blocked**. Do not ship on lint-green alone.

## Sign-off

- Gate status for tag `v1.0.0`: releasable when CI release workflow is green.
- Decision owner: candidate / quality engineer for this case study submission.
- Date: 2026-07-26
