# Platform audit — assessments + skills critical path

Scope: API + web together, ranked by client risk if this shipped tomorrow. Primary lens is the create → list → taxonomies → show → skill add/remove flow documented in [`tc-api/e2e-business-flow.md`](tc-api/e2e-business-flow.md). Login/signup is out of scope for this pass (token setup only).

Severity language: P0 blocker → P1 major (data/logic) → P2 minor → P3 cosmetic. Ranked top to bottom.

---

## Ship / do-not-ship line

**Do not ship** to a client while any **P0** on assessment skill persistence remains open. An assessor who builds a role, picks taxonomy skills, then removes one skill must see the same skill set the API stores. Today the web edit path does not meet that bar.

After the quality-net fixes in this engagement: **releasable for the assessment+skills path** if CI e2e + web payload checks are green, with remaining P1/P2 risks explicitly accepted below.

---

## Ranked risks

### 1. Web edit remove does not destroy nested skills (P0) — built wrong

| | |
|--|--|
| **Impact** | Assessor removes a skill in the UI and saves; API keeps the skill. Interview prompt / coverage still targets skills the assessor thought were gone. Data integrity failure. |
| **Evidence** | [`AssessmentEditPage.tsx`](../web/src/pages/assessments/AssessmentEditPage.tsx) calls `remove(index)` then PUTs only remaining skills. API nested destroy requires `{ id, _destroy: true }` ([`assessments_controller.rb`](../api/app/controllers/api/v1/assessments_controller.rb) permits `_destroy`; model `allow_destroy: true`). Rails does not delete omitted nested records. |
| **Repro** | Create assessment with two skills via API; open edit UI; remove one; save; `GET /assessments/:id` still shows both. |
| **Class** | Built wrong (API contract exists; UI ignores it). |
| **Status** | **Fix this pass** (payload builder + edit submit). |

### 2. Taxonomy pick drops `skill_id` / `scope_exclude` (P0) — built wrong

| | |
|--|--|
| **Impact** | Skills chosen “from B7 taxonomy” are stored without taxonomy id. Downstream continuity (re-read match, prompt grounding, reporting) cannot prove the skill is the catalog row. `is_custom: false` with null `skill_id` is a false taxonomy claim. |
| **Evidence** | [`SkillPicker.tsx`](../web/src/components/assessment/SkillPicker.tsx) `handleSelect` sets `skill_id: undefined` and omits `scope_exclude`. E2E TC-E2E-005 requires persisted `skill_id == $TAX_SKILL_ID`. |
| **Class** | Built wrong. |
| **Status** | **Fix this pass**. |

### 3. Missing product inputs for the business flow (P1) — missing spec

| | |
|--|--|
| **Impact** | No in-repo PRD / Given-When-Then AC / design plan for assessment builder. Cannot close “built wrong vs never defined” without reconstructing intent from code + notes. |
| **Evidence** | E2E references `documents/notes/business-flow.md` — **file absent**. Only candidate brief + manual TCs exist. |
| **Class** | Missing / ambiguous spec (first-class risk per brief). |
| **Status** | **Mitigate this pass** via DoR gate + link TCs as acceptance scenarios; full PRD not authored here. |

### 4. Lint-only CI cannot catch skill continuity defects (P1) — process

| | |
|--|--|
| **Impact** | Regressions on create/list/show/skill add-remove ship silently. |
| **Evidence** | [`.github/workflows/lint.yml`](../.github/workflows/lint.yml) only; no `api/spec`, no web tests. |
| **Class** | Missing quality net. |
| **Status** | **Fix this pass** (automate TC-E2E + web payload checks). |

### 5. Create response omits `skills` key used by show/update (P1) — built inconsistent

| | |
|--|--|
| **Impact** | Clients that trust the 201 body for skill state can under-read; must always re-GET. Easy false confidence in UI after create. |
| **Evidence** | `create` returns raw AR `assessment:`; `show`/`update` use `assessment_with_skills_json` → `skills:`. |
| **Class** | Built wrong / inconsistent contract. |
| **Status** | **Accept with owner** (assessor web always navigates away; API e2e re-reads). Owner: platform engineer on next contract pass. |

### 6. `system_prompt_generated: true` is enqueue-success, not generation-success (P1) — built wrong

| | |
|--|--|
| **Impact** | UI/API claim prompt was generated when only Sidekiq job was queued; worker failure leaves empty prompt while flag says success. |
| **Evidence** | Controller sets flag on `perform_async`; no wait/check of `system_prompt` column. |
| **Class** | Built wrong (misleading outcome signal). |
| **Status** | **Accept with owner** this pass (out of e2e continuity core). Owner: API owner; track as known risk. |

### 7. Skill taxonomy GET response key mismatch (P1) — built wrong

| | |
|--|--|
| **Impact** | `skillTaxonomiesApi.get` expects `{ skill_taxonomy }`; API returns `{ skill }`. Detail fetch fails if used. List path (`skill_taxonomies`) works. |
| **Evidence** | [`skillTaxonomies.ts`](../web/src/services/skillTaxonomies.ts) vs `SkillTaxonomiesController#show`. |
| **Class** | Built wrong (web↔API seam). |
| **Status** | **Fix this pass** (align client key). |

### 8. Web `skill_id` typed as number; taxonomy ids are strings (P2) — built wrong

| | |
|--|--|
| **Impact** | Type/UI badge (`SK-${padStart(number)}`) misrepresents `SK-ENG-001`. |
| **Evidence** | [`types/index.ts`](../web/src/types/index.ts); [`SkillCard.tsx`](../web/src/components/assessment/SkillCard.tsx). |
| **Class** | Built wrong. |
| **Status** | **Fix this pass** with taxonomy payload fix. |

### 9. Tenant fail-open when `tenant_id` unset (P2) — accepted background

| | |
|--|--|
| **Impact** | Cross-tenant list leak if middleware leaves tenant unresolved. |
| **Evidence** | [`TenantScoped`](../api/app/models/concerns/tenant_scoped.rb) returns `all` when key absent. |
| **Status** | **Accept with owner** — does not break happy-path JWT+scheme flow used by e2e. Owner: platform security. |

### 10. No seeded admin user (P2) — missing fixture

| | |
|--|--|
| **Impact** | Local/CI login for assessor flows is manual and fragile. |
| **Evidence** | `seeds.rb` org + taxonomies only. |
| **Status** | **Fix this pass** (seed deterministic admin for test/local). |

### 11. Login/signup UI seams (P3 / out of scope)

Signup → `POST /signup` with no API route; default web host `3000` vs API `3001`. Noted only; **not** prioritized this pass.

---

## Systemic pattern

Several issues recur because **the web treats the API as a dump of the current form state**, while the API’s nested-attributes contract is **incremental and destroy-explicit**. Combined with dropping taxonomy identifiers at the picker, the UI can look correct while the database holds a different skill set. That is the class of defect the quality net must catch: **persisted continuity across hops**, not HTTP 200 alone.

---

## What this engagement will gate

Before client delivery of assessment builder:

1. Automated API chain TC-E2E-001…008 green (persisted id/name/skills).
2. Web payload checks: taxonomy retains `skill_id` + `scope_exclude`; edit remove emits `_destroy`.
3. Definition-of-Ready PR gate: no merge without linked spec/AC/design pointers.
4. Honest release decision on remaining accepted risks (items 5, 6, 9).
