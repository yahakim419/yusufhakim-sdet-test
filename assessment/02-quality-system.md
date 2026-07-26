# Quality system

Small, sharp net for the **assessments + skills** critical path. Lives **outside** `api/` and `web/` (product freeze this pass).

## Assumption

Task 3 fullstack “fix to green” in product code is **out of scope**. Open P0/P1s stay open; release stays **blocked**. Green on the external API e2e proves the **API nested-attributes contract**, not the web builder payload.

## What it protects

| Check | Protects | Maps to |
|-------|----------|---------|
| DoR PR gate | No merge without linked Spec/PRD, acceptance criteria, design plan | Audit #3 (missing inputs) |
| External curl e2e | Create → list → taxonomies → show → taxonomy/custom skill add → selective `_destroy` with re-read | TC-E2E-001…008 |
| Web payload contract doc | Documents `_destroy` + taxonomy identity expected of the client | Audit #1, #2 (not automated in `web/`) |
| Lint (existing) | RuboCop / ESLint / tsc | Hygiene only |

## What it deliberately does not cover

- Product fixes under `api/` or `web/`
- Web UI / Vitest / Playwright (builder seams remain audit **open**)
- In-tree RSpec under `api/spec` as the submission story (files may exist from prior work; CI does not depend on editing them)
- Login/signup UI matrices
- Portfolio / fit-gap / Sidekiq generation correctness
- Tenant fail-open hardening

## How to run

### External e2e (needs running API + Postgres + Redis)

```bash
# Start API (Docker or local — see repo README / api/README.md), then:
export BASE_URL=http://localhost:3001
export E2E_EMAIL=admin@test-corp.example   # or your admin
export E2E_PASSWORD='Password1!'             # or your password
export X_TENANT_SCHEME=test-corp
./assessment/scripts/e2e_business_flow.sh
```

CI helper (boots API after `db:prepare` + `db:seed` without editing `api/` sources):

```bash
.github/scripts/run-external-e2e.sh
```

Credentials must come from env (or an already-seeded admin). This pass does **not** change `api/db/seeds.rb`.

### Definition of Ready (local)

```bash
.github/scripts/check-dor.sh /tmp/pr-body.md
```

CI: [`.github/workflows/quality.yml`](../.github/workflows/quality.yml) on PR/`main`; release tag gate in [`.github/workflows/release.yml`](../.github/workflows/release.yml).

### Web contract (docs only)

[`scripts/web_payload_contract.md`](scripts/web_payload_contract.md) + [`fixtures/assessment_skills_destroy.json`](fixtures/assessment_skills_destroy.json).

## Design notes (DoR links)

Nested skill updates use Rails `accepts_nested_attributes_for` with `allow_destroy: true`. A correct client must:

1. Send taxonomy identity (`skill_id`, anchors, `scope_exclude`) when picking from B7.
2. On edit save, send `{ id, _destroy: true }` for skills removed in the UI.

Omitting a nested record does **not** delete it.

## Red → green (this pass)

### What stays red / open

1. **Web edit remove without `_destroy`** — audit P0; product freeze.
2. **Taxonomy pick dropping `skill_id` / `scope_exclude`** — audit P0; product freeze.
3. **Create 201 omits `skills`**, **`system_prompt_generated` honesty**, **taxonomy GET key mismatch** — audit P1s; open.
4. Release tag workflow surfaces **BLOCKED** while those remain.

### What went green (process only)

1. **DoR gate** — PR without Spec/AC/design links fails `dor-gate`.
2. **External e2e script** — TC-E2E-001…008 asserts API persisted continuity when credentials and seed data exist.
3. **Release honesty** — tag gate does not claim releasable for client skill-builder trustworthiness.

Root cause of the P0 class (unchanged, unfixed): web can treat nested skills as a full form replace; API is incremental/destroy-explicit. This pass documents and gates that class; it does **not** patch the client.
