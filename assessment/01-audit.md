# Platform audit — assessments + skills critical path

Scope: API + web together, ranked by client risk if this shipped tomorrow. Primary lens is the create → list → taxonomies → show → skill add/remove flow in [`tc-api/e2e-business-flow.md`](tc-api/e2e-business-flow.md). Login is token setup only.

Severity: P0 blocker → P1 major (data/logic) → P2 minor → P3 cosmetic. Ranked top to bottom.

**Engagement constraint:** this pass freezes `api/` and `web/` (no product-code fixes). Statuses are **open**, **accepted**, **mitigated (process)**, or **out of scope** — not “fixed this pass.”

---

## Ship / do-not-ship line

**Do not ship** to a client while any **P0** on assessment skill persistence (web↔API seam) remains open without an explicit named-owner acceptance. An assessor who builds a role, picks taxonomy skills, then removes one skill must see the same skill set the API stores.

Under the product-code freeze, open P0/P1 items below keep this version **blocked** for client delivery of the assessment builder. Process gates (DoR + external e2e) harden the workflow; they do not clear product risk by themselves.

---

## Ranked risks

### 1. Web edit remove does not destroy nested skills (P0) — built wrong

| | |
|--|--|
| **Impact** | Assessor removes a skill in the UI and saves; API may keep the skill if the client omits `{ id, _destroy: true }`. Interview prompt / coverage still targets skills the assessor thought were gone. |
| **Evidence** | Rails nested destroy requires `_destroy` ([`assessments_controller.rb`](../api/app/controllers/api/v1/assessments_controller.rb) permits `_destroy`; model `allow_destroy: true`). Omitting a nested record does not delete it. Edit UI historically called form `remove` then PUT remaining skills only. |
| **Repro** | Create assessment with two skills via API; open edit UI; remove one; save; `GET /assessments/:id` still shows both if payload lacked `_destroy`. |
| **Class** | Built wrong (API contract exists; UI can ignore it). |
| **Status** | **Open** — product freeze; no fix this pass. |

### 2. Taxonomy pick drops `skill_id` / `scope_exclude` (P0) — built wrong

| | |
|--|--|
| **Impact** | Skills chosen “from B7 taxonomy” can be stored without taxonomy id. Continuity (re-read match, prompt grounding) cannot prove the catalog row. `is_custom: false` with null `skill_id` is a false taxonomy claim. |
| **Evidence** | Skill picker path can set `skill_id: undefined` and omit `scope_exclude`. TC-E2E-005 requires persisted `skill_id == $TAX_SKILL_ID` on the API path. |
| **Class** | Built wrong (web↔API seam). |
| **Status** | **Open** — product freeze. |

### 3. Missing product inputs for the business flow (P1) — missing spec

| | |
|--|--|
| **Impact** | No in-repo PRD / Given-When-Then AC / design plan for assessment builder. Hard to close “built wrong vs never defined.” |
| **Evidence** | E2E references `documents/notes/business-flow.md` — **file absent**. Manual TCs in `assessment/tc-api/` are the best stand-in. |
| **Class** | Missing / ambiguous spec (first-class risk per brief). |
| **Status** | **Mitigated (process)** via DoR PR gate + TC-E2E as linked acceptance scenarios. Full PRD not authored. |

### 4. Process gap without an external continuity gate (P1) — process

| | |
|--|--|
| **Impact** | Regressions on create/list/show/skill add-remove can ship if only lint runs. |
| **Evidence** | Lint workflow alone does not assert persisted skill state. |
| **Class** | Missing quality net. |
| **Status** | **Mitigated (process)** by external curl e2e ([`scripts/e2e_business_flow.sh`](scripts/e2e_business_flow.sh)) + DoR gate in CI. Does not fix product seams. |

### 5. Create response omits `skills` key used by show/update (P1) — built inconsistent

| | |
|--|--|
| **Impact** | Clients that trust the 201 body for skill state can under-read; must always re-GET. |
| **Evidence** | `create` returns raw AR `assessment:`; `show`/`update` use `assessment_with_skills_json` → `skills:`. |
| **Class** | Built wrong / inconsistent contract. |
| **Status** | **Open** — accepted only with named owner if ever shipped; default release **blocked**. Owner: platform API. |

### 6. `system_prompt_generated: true` is enqueue-success, not generation-success (P1) — built wrong

| | |
|--|--|
| **Impact** | Flag claims prompt generated when only Sidekiq job was queued; worker failure leaves empty prompt. |
| **Evidence** | Controller sets flag on `perform_async`; no wait/check of `system_prompt` column. |
| **Class** | Built wrong (misleading outcome signal). |
| **Status** | **Open** — owner: API owner. Blocks honest “prompt ready” claims. |

### 7. Skill taxonomy GET response key mismatch (P1) — built wrong

| | |
|--|--|
| **Impact** | Client expecting `{ skill_taxonomy }` vs API `{ skill }` breaks detail fetch if used. List path works. |
| **Evidence** | [`skillTaxonomies.ts`](../web/src/services/skillTaxonomies.ts) vs `SkillTaxonomiesController#show`. |
| **Class** | Built wrong (web↔API seam). |
| **Status** | **Open** — product freeze. |

### 8. Web `skill_id` typed as number; taxonomy ids are strings (P2) — built wrong

| | |
|--|--|
| **Impact** | Type/UI badge can misrepresent ids like `SK-ENG-001`. |
| **Evidence** | Web types / SkillCard label formatting vs string taxonomy ids. |
| **Class** | Built wrong. |
| **Status** | **Open** — product freeze. |

### 9. Tenant fail-open when `tenant_id` unset (P2) — background

| | |
|--|--|
| **Impact** | Cross-tenant list leak if middleware leaves tenant unresolved. |
| **Evidence** | [`TenantScoped`](../api/app/models/concerns/tenant_scoped.rb) returns `all` when key absent. |
| **Status** | **Accepted** for happy-path JWT+scheme flows only. Owner: platform security. Does not clear P0 ship line. |

### 10. Login/signup UI seams (P3 / out of scope)

Signup → `POST /signup` with no API route; default web host may disagree with API `3001`. Noted; **out of scope** this pass.

---

## Systemic pattern

Several issues recur because **the web can treat the API as a dump of the current form state**, while the API’s nested-attributes contract is **incremental and destroy-explicit**. Combined with dropped taxonomy identifiers at the picker, the UI can look correct while the database holds a different skill set.

That is the class of defect the quality net must catch: **persisted continuity across hops**, not HTTP 200 alone. Under the freeze, the external API e2e proves the **API** contract; it does **not** prove the web builder payload is correct — hence open P0s still block release.

---

## What this engagement gates (without product fixes)

1. External API chain TC-E2E-001…008 (persisted id/name/skills) via [`scripts/e2e_business_flow.sh`](scripts/e2e_business_flow.sh).
2. Definition-of-Ready PR gate: no merge without linked spec/AC/design pointers.
3. Honest release decision: **blocked** while items 1–2, 5–7 remain open without named-owner risk acceptance.
