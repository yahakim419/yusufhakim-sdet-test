# Quality system

Small, sharp net for the **assessments + skills** critical path. Not a coverage-percentage chase.

## What it protects

| Check | Protects | Maps to |
|-------|----------|---------|
| DoR PR gate | No merge without linked Spec/PRD, acceptance criteria, design plan | Audit #3 (missing inputs) |
| API e2e request spec | Create → list → taxonomies → show → taxonomy/custom skill add → selective `_destroy` with re-read assertions | TC-E2E-001…008 |
| Web payload unit tests | Taxonomy pick keeps `skill_id` + `scope_exclude`; edit remove emits `_destroy` | Audit #1, #2 |
| Lint (existing) | RuboCop / ESLint / tsc | Hygiene only |

## What it deliberately does not cover

- Login/signup UI and auth failure matrices
- Portfolio / fit-gap / Sidekiq generation correctness
- Full browser E2E (Playwright)
- Tenant fail-open hardening (accepted risk in audit)
- Prompt worker success vs enqueue (`system_prompt_generated` honesty)

## How to run

### API e2e (needs Postgres + Redis; see `api/README.md` / Docker)

```bash
cd api
# DB + SECRET_KEY_BASE configured for test
bundle exec rails db:prepare
bundle exec rspec spec/requests/e2e_business_flow_spec.rb
```

Seeded admin for local API login after `rails db:seed`:

- email: `admin@test-corp.example`
- password: `Password1!`

### Web payload tests

```bash
cd web
npm ci
npm test
```

### Definition of Ready (local)

```bash
.github/scripts/check-dor.sh /tmp/pr-body.md
```

CI: [`.github/workflows/quality.yml`](../.github/workflows/quality.yml) on PR/`main`; release tag gate in [`.github/workflows/release.yml`](../.github/workflows/release.yml).

## Design notes (for DoR links)

Nested skill updates use Rails `accepts_nested_attributes_for` with `allow_destroy: true`. The web must:

1. Send taxonomy identity (`skill_id`, anchors, `scope_exclude`) when picking from B7 — [`taxonomyToAssessmentSkill`](../web/src/lib/assessmentSkillsPayload.ts).
2. On edit save, send `{ id, _destroy: true }` for skills removed in the UI — [`buildNestedSkillsAttributes`](../web/src/lib/assessmentSkillsPayload.ts).

Omitting a nested record does **not** delete it.

## Red → green

### What was red

1. **Web edit remove** — UI `remove(index)` + PUT of remaining skills only; API kept deleted skills. Would fail any check requiring `_destroy` (unit test `buildNestedSkillsAttributes`; manual re-read after UI remove).
2. **Taxonomy pick** — `SkillPicker` set `skill_id: undefined` and dropped `scope_exclude`. Failed continuity vs TC-E2E-005 expectations and `taxonomyToAssessmentSkill` unit test.
3. **No automated net** — lint-only CI; business-flow defects invisible.
4. **Taxonomy GET client key** — expected `skill_taxonomy`, API returns `skill`.

### What changed

- Extracted payload helpers; wired `SkillPicker` + `AssessmentEditPage`.
- Fixed `skillTaxonomiesApi.get` response key; `skill_id` typing; SkillCard label.
- Added RSpec e2e business-flow + Vitest payload tests + DoR gate + quality/release workflows.
- Seeded deterministic admin user.

### What is green now

- `npm test` — taxonomy + `_destroy` payload contracts.
- `rspec …e2e_business_flow_spec.rb` — API nested add/destroy continuity.
- PR without DoR links fails `dor-gate`.

Root cause (not symptom): web treated the form as a full replace of nested skills; API is incremental/destroy-explicit. Fix aligns the client with the API contract instead of weakening tests.
