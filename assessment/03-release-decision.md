# Release decision — v1.0.0

## Recommendation

**Blocked** for client delivery of the assessment + skills builder path.

Open P0/P1 product risks remain, and this engagement froze `api/` and `web/` (no fullstack fix-to-green). Honesty beats a green-looking ship.

## What the gate checked

| Gate | Result |
|------|--------|
| Lint (API RuboCop, web ESLint/tsc) | Available via `lint.yml` |
| External API e2e (TC-E2E-001…008) | Runs on tag via `release.yml` — proves API nested add/destroy when seeded |
| DoR PR gate | Enforced on pull requests (`dor-gate`) |
| Tag workflow `release.yml` | Surfaces **BLOCKED** and fails the release job |

Human review artifacts: `assessment/01-audit.md`, `assessment/02-quality-system.md`, this file, `RELEASE_NOTES.md`.

## What it found

- External e2e can go green on the **API** contract (create/list/show/skill add + selective `_destroy`).
- That does **not** clear web↔API seam P0s (edit remove without `_destroy`; taxonomy pick dropping identity).
- Create response shape, `system_prompt_generated` honesty, and taxonomy GET key mismatch remain open P1s.
- Missing product PRD is mitigated only by DoR + TC links, not by a full spec.

## Open risks (block release)

| Risk | Severity | Owner | Notes |
|------|----------|-------|-------|
| Web edit remove omits `_destroy` | P0 | Platform web — unfixed this pass | Blocks ship |
| Taxonomy pick drops `skill_id` / `scope_exclude` | P0 | Platform web — unfixed | Blocks ship |
| Create 201 omits `skills` key | P1 | Platform API | Blocks honest contract claim |
| `system_prompt_generated` = enqueue only | P1 | Platform API | Blocks “prompt ready” claim |
| Taxonomy GET key mismatch (`skill` vs `skill_taxonomy`) | P1 | Platform web/API | Blocks detail-fetch trust |

## Accepted background (does not clear P0 ship line)

| Risk | Severity | Owner |
|------|----------|-------|
| Tenant fail-open if tenant unset | P2 | Platform security |
| Login/signup UI seams | P3 | Out of scope |

## If gate goes red on e2e

API continuity failures also block. Do not ship on lint-green alone.

## Sign-off

- Gate status for tag `v1.0.0`: **BLOCKED**
- Decision owner: candidate / quality engineer for this case study submission
- Date: 2026-07-26
- Assumption recorded: no product-code changes under `api/` or `web/` this pass
