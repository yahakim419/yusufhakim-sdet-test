# E2E — Business Flow (Assessments + Skills)

Chained process suite from [documents/notes/business-flow.md](../../documents/notes/business-flow.md): create → list → taxonomies → show, then nested skill add/remove (taxonomy vs custom) with re-read assertions.

**Not** ordinary field validation (see [02-assessments.md](02-assessments.md), [06-skill-taxonomies.md](06-skill-taxonomies.md)). Focus: cross-step id/name/skill continuity and selective nested `_destroy`.

Requires `$TOKEN` from [01-auth-and-health.md](01-auth-and-health.md) / [README.md](README.md). No login steps here.

Evidence: `api/app/controllers/api/v1/assessments_controller.rb`, `api/app/models/assessment.rb`, `api/app/models/assessment_skill.rb`, `api/app/controllers/api/v1/skill_taxonomies_controller.rb`, `documents/notes/business-flow.md`.

| Priority | Count |
|----------|------:|
| P0 | 5 |
| P1 | 3 |
| P2 | 0 |
| P3 | 0 |
| **Total** | **8** |

Execute **TC-E2E-001 → TC-E2E-008** in order on one assessment.

---

### TC-E2E-001 — Create assessment (baseline, returns id)
- **Priority:** P0
- **Method / Path:** `POST /api/v1/assessments`
- **Auth:** Bearer JWT
- **Precondition:** `$TOKEN` valid; seeded tenant usable
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/assessments" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "assessment": {
        "name": "E2E Business Flow Assessment",
        "time_limit_min": 30,
        "language": "en"
      }
    }'
  ```
- **Expected status:** `201`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - Top-level keys: `assessment`, `system_prompt_generated`
  - `assessment.id` present (integer)
  - `assessment.name` == `"E2E Business Flow Assessment"`
  - `assessment.time_limit_min` == `30`
  - `system_prompt_generated` == `true`
  ```json
  {
    "assessment": {
      "id": 1,
      "name": "E2E Business Flow Assessment",
      "time_limit_min": 30
    },
    "system_prompt_generated": true
  }
  ```
- **Expected state change:** Assessment persisted for later list/show/skill mutations
- **Save:** `$ASSESSMENT_ID` = `.assessment.id`, `$ASSESSMENT_NAME` = `.assessment.name`

---

### TC-E2E-002 — List assessments (created id and name present)
- **Priority:** P0
- **Method / Path:** `GET /api/v1/assessments`
- **Auth:** Bearer JWT
- **Precondition:** TC-E2E-001 passed; `$ASSESSMENT_ID`, `$ASSESSMENT_NAME` set
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/assessments?page=1&per_page=20" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `200`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - Top-level keys: `assessments`, `meta`
  - Some `assessments[x]` has **both** `id` == `$ASSESSMENT_ID` **and** `name` == `$ASSESSMENT_NAME` (reject name-only match on a different id)
  ```json
  {
    "assessments": [
      {
        "id": 1,
        "name": "E2E Business Flow Assessment"
      }
    ],
    "meta": {
      "current_page": 1,
      "total_pages": 1,
      "total_count": 1,
      "per_page": 20
    }
  }
  ```
- **Expected state change:** `n/a` (read)

---

### TC-E2E-003 — List skill taxonomies (feed later taxonomy skill add)
- **Priority:** P1
- **Method / Path:** `GET /api/v1/skill_taxonomies`
- **Auth:** Bearer JWT
- **Precondition:** TC-E2E-001–002 passed; `$TOKEN` valid
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/skill_taxonomies" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `200`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - Top-level key: `skill_taxonomies` (non-empty array when seeded)
  - Pick one item; save its `skill_id`, `skill_label`, anchors, scopes for TC-E2E-005
  ```json
  {
    "skill_taxonomies": [
      {
        "skill_id": "SK-ENG-001",
        "skill_label": "React / Frontend Development Core",
        "category": "engineering",
        "scope_include": "...",
        "scope_exclude": "...",
        "l1_anchor": "...",
        "l2_anchor": "...",
        "l3_anchor": "...",
        "l4_anchor": "...",
        "l5_anchor": "..."
      }
    ]
  }
  ```
- **Expected state change:** `n/a` (read; must feed PUT add taxonomy — not a dead hop)
- **Save:** `$TAX_SKILL_ID`, `$TAX_SKILL_LABEL`, `$TAX_L1`…`$TAX_L5`, `$TAX_SCOPE_INCLUDE`, `$TAX_SCOPE_EXCLUDE` from chosen row

---

### TC-E2E-004 — Get assessment by id (baseline matches create after taxonomy hop)
- **Priority:** P0
- **Method / Path:** `GET /api/v1/assessments/:id`
- **Auth:** Bearer JWT
- **Precondition:** TC-E2E-001–003 passed; `$ASSESSMENT_ID` set
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/assessments/$ASSESSMENT_ID" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `200`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - Top-level key: `assessment`
  - `assessment.id` == `$ASSESSMENT_ID`
  - `assessment.name` == `$ASSESSMENT_NAME`
  - `assessment.time_limit_min` == `30`
  - `assessment.skills` is array (empty or unchanged from create — intervening taxonomy GET must not alter this assessment)
  ```json
  {
    "assessment": {
      "id": 1,
      "name": "E2E Business Flow Assessment",
      "time_limit_min": 30,
      "skills": []
    }
  }
  ```
- **Expected state change:** `n/a` (read continuity after TC-E2E-003)

---

### TC-E2E-005 — PUT add taxonomy skill then re-read (is_custom false)
- **Priority:** P0
- **Method / Path:** `PUT /api/v1/assessments/:id` then `GET /api/v1/assessments/:id`
- **Auth:** Bearer JWT
- **Precondition:** TC-E2E-003–004 passed; `$TAX_SKILL_*` set from taxonomies
- **curl:**
  ```bash
  curl -i -X PUT "$BASE/api/v1/assessments/$ASSESSMENT_ID" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"assessment\": {
        \"name\": \"$ASSESSMENT_NAME\",
        \"time_limit_min\": 30,
        \"language\": \"en\",
        \"assessment_skills_attributes\": [
          {
            \"skill_id\": \"$TAX_SKILL_ID\",
            \"skill_label\": \"$TAX_SKILL_LABEL\",
            \"is_custom\": false,
            \"scope_include\": \"$TAX_SCOPE_INCLUDE\",
            \"scope_exclude\": \"$TAX_SCOPE_EXCLUDE\",
            \"l1_anchor\": \"$TAX_L1\",
            \"l2_anchor\": \"$TAX_L2\",
            \"l3_anchor\": \"$TAX_L3\",
            \"l4_anchor\": \"$TAX_L4\",
            \"l5_anchor\": \"$TAX_L5\",
            \"expected_level\": 3,
            \"display_order\": 1
          }
        ]
      }
    }"

  curl -i "$BASE/api/v1/assessments/$ASSESSMENT_ID" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `200` (PUT); `200` (GET)
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - PUT: `system_prompt_generated` == `true`; response `assessment.skills` includes taxonomy skill
  - GET re-read: some skill with `skill_id` == `$TAX_SKILL_ID`, `skill_label` == `$TAX_SKILL_LABEL`, `is_custom` == `false`
  - Persist nested skill id for later destroy
  ```json
  {
    "assessment": {
      "id": 1,
      "name": "E2E Business Flow Assessment",
      "skills": [
        {
          "id": 10,
          "skill_id": "SK-ENG-001",
          "skill_label": "React / Frontend Development Core",
          "is_custom": false,
          "display_order": 1
        }
      ]
    },
    "system_prompt_generated": true
  }
  ```
- **Expected state change:** Taxonomy-backed skill attached to `$ASSESSMENT_ID`
- **Save:** `$TAX_ASSESSMENT_SKILL_ID` = matching `skills[].id`

---

### TC-E2E-006 — PUT add custom skill then re-read (is_custom true; both skills present)
- **Priority:** P0
- **Method / Path:** `PUT /api/v1/assessments/:id` then `GET /api/v1/assessments/:id`
- **Auth:** Bearer JWT
- **Precondition:** TC-E2E-005 passed; `$TAX_ASSESSMENT_SKILL_ID` set (keep existing taxonomy skill)
- **curl:**
  ```bash
  curl -i -X PUT "$BASE/api/v1/assessments/$ASSESSMENT_ID" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"assessment\": {
        \"name\": \"$ASSESSMENT_NAME\",
        \"time_limit_min\": 30,
        \"language\": \"en\",
        \"assessment_skills_attributes\": [
          {
            \"skill_id\": null,
            \"skill_label\": \"E2E Custom Negotiation\",
            \"is_custom\": true,
            \"scope_include\": \"Stakeholder alignment\",
            \"scope_exclude\": \"Legal drafting\",
            \"l1_anchor\": \"L1 custom\",
            \"l2_anchor\": \"L2 custom\",
            \"l3_anchor\": \"L3 custom\",
            \"l4_anchor\": \"L4 custom\",
            \"l5_anchor\": \"L5 custom\",
            \"expected_level\": 2,
            \"display_order\": 2
          }
        ]
      }
    }"

  curl -i "$BASE/api/v1/assessments/$ASSESSMENT_ID" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `200` (PUT); `200` (GET)
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - GET re-read: skill with `skill_label` == `"E2E Custom Negotiation"`, `is_custom` == `true`
  - GET re-read: taxonomy skill from TC-E2E-005 still present (`id` == `$TAX_ASSESSMENT_SKILL_ID` or same `skill_id`) — mixed-state must hold
  ```json
  {
    "assessment": {
      "id": 1,
      "skills": [
        {
          "id": 10,
          "skill_id": "SK-ENG-001",
          "is_custom": false
        },
        {
          "id": 11,
          "skill_label": "E2E Custom Negotiation",
          "is_custom": true,
          "display_order": 2
        }
      ]
    },
    "system_prompt_generated": true
  }
  ```
- **Expected state change:** Custom skill added; taxonomy skill not dropped by nested add
- **Save:** `$CUSTOM_ASSESSMENT_SKILL_ID` = custom `skills[].id`

---

### TC-E2E-007 — PUT destroy taxonomy skill only then re-read (custom remains)
- **Priority:** P1
- **Method / Path:** `PUT /api/v1/assessments/:id` then `GET /api/v1/assessments/:id`
- **Auth:** Bearer JWT
- **Precondition:** TC-E2E-006 passed; both `$TAX_ASSESSMENT_SKILL_ID` and `$CUSTOM_ASSESSMENT_SKILL_ID` set
- **Note:** Nested skill remove via `_destroy` — **not** `DELETE /api/v1/assessments/:id`
- **curl:**
  ```bash
  curl -i -X PUT "$BASE/api/v1/assessments/$ASSESSMENT_ID" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"assessment\": {
        \"name\": \"$ASSESSMENT_NAME\",
        \"time_limit_min\": 30,
        \"language\": \"en\",
        \"assessment_skills_attributes\": [
          {
            \"id\": $TAX_ASSESSMENT_SKILL_ID,
            \"_destroy\": true
          }
        ]
      }
    }"

  curl -i "$BASE/api/v1/assessments/$ASSESSMENT_ID" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `200` (PUT); `200` (GET)
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - GET: no skill with `id` == `$TAX_ASSESSMENT_SKILL_ID` (and no remaining row with that taxonomy `skill_id` unless intentionally re-added)
  - GET: custom skill still present (`id` == `$CUSTOM_ASSESSMENT_SKILL_ID`, `is_custom` == `true`)
  ```json
  {
    "assessment": {
      "id": 1,
      "skills": [
        {
          "id": 11,
          "skill_label": "E2E Custom Negotiation",
          "is_custom": true
        }
      ]
    },
    "system_prompt_generated": true
  }
  ```
- **Expected state change:** Taxonomy nested skill removed; custom skill intact

---

### TC-E2E-008 — PUT destroy custom skill then re-read
- **Priority:** P1
- **Method / Path:** `PUT /api/v1/assessments/:id` then `GET /api/v1/assessments/:id`
- **Auth:** Bearer JWT
- **Precondition:** TC-E2E-007 passed; `$CUSTOM_ASSESSMENT_SKILL_ID` still present on assessment
- **Note:** Nested skill remove via `_destroy` — **not** delete assessment
- **curl:**
  ```bash
  curl -i -X PUT "$BASE/api/v1/assessments/$ASSESSMENT_ID" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"assessment\": {
        \"name\": \"$ASSESSMENT_NAME\",
        \"time_limit_min\": 30,
        \"language\": \"en\",
        \"assessment_skills_attributes\": [
          {
            \"id\": $CUSTOM_ASSESSMENT_SKILL_ID,
            \"_destroy\": true
          }
        ]
      }
    }"

  curl -i "$BASE/api/v1/assessments/$ASSESSMENT_ID" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `200` (PUT); `200` (GET)
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - GET: no skill with `id` == `$CUSTOM_ASSESSMENT_SKILL_ID`
  - GET: `assessment.skills` does not include `"E2E Custom Negotiation"`
  - Assessment itself still exists (`assessment.id` == `$ASSESSMENT_ID`)
  ```json
  {
    "assessment": {
      "id": 1,
      "name": "E2E Business Flow Assessment",
      "skills": []
    },
    "system_prompt_generated": true
  }
  ```
- **Expected state change:** Custom nested skill removed; assessment row remains

---

## Coverage gate ([coverage-rules.mdc](../../.cursor/rules/coverage-rules.mdc))

Evaluated for endpoints in this flow. E2E owns process/happy path; ordinary validation/auth/404 stay in suites 01/02/06.

| Dimension | Status | Where |
|-----------|--------|--------|
| Functional — happy path | Covered | TC-E2E-001…008 |
| Functional — main business flow | Covered | create → list → taxonomies → show → skill add/remove |
| Functional — alternative valid flow | Covered | taxonomy skill path vs custom skill path on same assessment |
| Input validation | Traced | [02-assessments.md](02-assessments.md), [06-skill-taxonomies.md](06-skill-taxonomies.md) |
| HTTP — success | Covered | 201 create; 200 list/taxonomies/show/update |
| HTTP — client error / not found | Traced | suite 02 / 06 |
| HTTP — authentication | Traced | TC-ASM-014, TC-TAX-006; residual GAP on GET assessments missing-token |
| HTTP — authorization / conflict | Partial / N/A | assessor JWT assumed; no conflict semantics evidenced |
| Business — process consistency | Covered | id+name list match; show after intervening GET; selective `_destroy` leaves other skill |
| Business — invalid state / duplicate | N/A / suite | not in this note |
| Error handling / worker failure | Partial | assert `system_prompt_generated` flag only; worker failure UNVERIFIED |
| Response validation | Covered | schema keys, types, business values, side-effect flag; re-read after each mutation |

**Residual gaps (do not invent in E2E):** missing-token on `GET /assessments` and `GET /assessments/:id`; non-assessor authorization variants; async system-prompt content after skill change.
