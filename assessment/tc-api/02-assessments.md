# 02 — Assessments

Requires `$TOKEN` from [01-auth-and-health.md](01-auth-and-health.md).

Evidence: `api/app/controllers/api/v1/assessments_controller.rb`, `api/app/models/assessment.rb`, `api/app/models/assessment_skill.rb`.

Validations (model):
- `name` presence
- `time_limit_min` presence; inclusion `[10, 30, 45, 60, 90]`
- `language` optional; inclusion `en` / `id` when present
- nested skills: `skill_label`, `l1`–`l5_anchor`, `display_order` presence; `expected_level` 1–5 if set

---

### TC-ASM-001 — List assessments (paginated)
- **Priority:** P0
- **Method / Path:** `GET /api/v1/assessments`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/assessments?page=1&per_page=20" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `200`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - Top-level keys: `assessments`, `meta`
  - `assessments` is array
  - Each item may include: `id`, `name`, `time_limit_min`, `language`, `created_at`, `latest_session`
  - `meta` has `current_page`, `total_pages`, `total_count`, `per_page`
  ```json
  {
    "assessments": [
      {
        "id": 1,
        "name": "...",
        "time_limit_min": 30,
        "language": "en",
        "system_prompt": null,
        "created_by": 1,
        "created_at": "...",
        "updated_at": "...",
        "latest_session": null
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

---

### TC-ASM-002 — Create assessment
- **Priority:** P0
- **Method / Path:** `POST /api/v1/assessments`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/assessments" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "assessment": {
        "name": "QE API Test Assessment",
        "time_limit_min": 30,
        "language": "en",
        "assessment_skills_attributes": [
          {
            "skill_id": "SK-ENG-001",
            "skill_label": "React / Frontend Development Core",
            "is_custom": false,
            "scope_include": "Component design",
            "scope_exclude": "Backend",
            "l1_anchor": "L1",
            "l2_anchor": "L2",
            "l3_anchor": "L3",
            "l4_anchor": "L4",
            "l5_anchor": "L5",
            "expected_level": 3,
            "display_order": 1
          }
        ]
      }
    }'
  ```
- **Expected status:** `201`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - Top-level keys: `assessment`, `system_prompt_generated`
  - `system_prompt_generated` == `true`
  - `assessment` has `id`, `name` == `"QE API Test Assessment"`, `time_limit_min` == `30`
  ```json
  {
    "assessment": {
      "id": 1,
      "name": "QE API Test Assessment",
      "time_limit_min": 30
    },
    "system_prompt_generated": true
  }
  ```
- **Save:** `$ASSESSMENT_ID` from `.assessment.id`

---

### TC-ASM-003 — Create assessment validation error (missing name)
- **Priority:** P1
- **Method / Path:** `POST /api/v1/assessments`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/assessments" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "assessment": {
        "time_limit_min": 30,
        "language": "en"
      }
    }'
  ```
- **Expected status:** `422`
- **Expected message:** `Name can't be blank`
- **Expected payload (validate):**
  - `errors[0].status` == `422`
  - `errors[0].message` is non-empty string
  ```json
  {
    "errors": [
      { "status": 422, "message": "Name can't be blank" }
    ]
  }
  ```

---

### TC-ASM-004 — Create assessment rejects invalid time_limit_min
- **Priority:** P1
- **Method / Path:** `POST /api/v1/assessments`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/assessments" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "assessment": {
        "name": "Bad Time Limit",
        "time_limit_min": 25,
        "language": "en"
      }
    }'
  ```
- **Expected status:** `422`
- **Expected message:** (inclusion validation; message mentions `Time limit min`)
- **Expected payload (validate):**
  - `errors[0].status` == `422`
  - `errors[0].message` non-empty
  ```json
  {
    "errors": [
      { "status": 422, "message": "Time limit min is not included in the list" }
    ]
  }
  ```

---

### TC-ASM-005 — Create assessment rejects invalid language
- **Priority:** P1
- **Method / Path:** `POST /api/v1/assessments`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/assessments" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "assessment": {
        "name": "Bad Language",
        "time_limit_min": 30,
        "language": "fr"
      }
    }'
  ```
- **Expected status:** `422`
- **Expected message:** (inclusion validation; message mentions `Language`)
- **Expected payload (validate):**
  - `errors[0].status` == `422`
  ```json
  {
    "errors": [
      { "status": 422, "message": "Language is not included in the list" }
    ]
  }
  ```

---

### TC-ASM-006 — Create assessment missing assessment root key
- **Priority:** P1
- **Method / Path:** `POST /api/v1/assessments`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/assessments" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name":"No Root Key","time_limit_min":30}'
  ```
- **Expected status:** `422`
- **Expected message:** (ParameterMissing; assert non-empty `errors[0].message`)
- **Expected payload (validate):**
  - `errors[0].status` == `422`
  - Must **not** create an assessment

---

### TC-ASM-007 — Create assessment with empty name
- **Priority:** P1
- **Method / Path:** `POST /api/v1/assessments`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/assessments" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "assessment": {
        "name": "",
        "time_limit_min": 30,
        "language": "en"
      }
    }'
  ```
- **Expected status:** `422`
- **Expected message:** `Name can't be blank`
- **Expected payload (validate):**
  ```json
  {
    "errors": [
      { "status": 422, "message": "Name can't be blank" }
    ]
  }
  ```

---

### TC-ASM-008 — Get assessment by id
- **Priority:** P0
- **Method / Path:** `GET /api/v1/assessments/:id`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/assessments/$ASSESSMENT_ID" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `200`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - Top-level key: `assessment`
  - `assessment.skills` is array
  - Skill items include: `id`, `skill_id`, `skill_label`, `l1_anchor`…`l5_anchor`, `expected_level`, `display_order`
  ```json
  {
    "assessment": {
      "id": 1,
      "name": "QE API Test Assessment",
      "time_limit_min": 30,
      "language": "en",
      "skills": [
        {
          "id": 1,
          "skill_id": "SK-ENG-001",
          "skill_label": "React / Frontend Development Core",
          "is_custom": false,
          "expected_level": 3,
          "display_order": 1
        }
      ]
    }
  }
  ```

---

### TC-ASM-009 — Get assessment not found
- **Priority:** P1
- **Method / Path:** `GET /api/v1/assessments/:id`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/assessments/999999" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `404`
- **Expected message:** `Assessment not found`
- **Expected payload (validate):**
  ```json
  {
    "errors": [
      { "status": 404, "message": "Assessment not found" }
    ]
  }
  ```

---

### TC-ASM-010 — Update assessment
- **Priority:** P0
- **Method / Path:** `PUT /api/v1/assessments/:id`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i -X PUT "$BASE/api/v1/assessments/$ASSESSMENT_ID" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "assessment": {
        "name": "QE API Test Assessment Updated",
        "time_limit_min": 45,
        "language": "en"
      }
    }'
  ```
- **Expected status:** `200`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - `system_prompt_generated` == `true`
  - `assessment.name` == `"QE API Test Assessment Updated"`
  - `assessment.time_limit_min` == `45`
  - `assessment.skills` present (array)
  ```json
  {
    "assessment": {
      "id": 1,
      "name": "QE API Test Assessment Updated",
      "time_limit_min": 45,
      "skills": []
    },
    "system_prompt_generated": true
  }
  ```

---

### TC-ASM-011 — Update assessment not found
- **Priority:** P2
- **Method / Path:** `PUT /api/v1/assessments/:id`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i -X PUT "$BASE/api/v1/assessments/999999" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "assessment": { "name": "Nope", "time_limit_min": 30 }
    }'
  ```
- **Expected status:** `404`
- **Expected message:** `Assessment not found`
- **Expected payload (validate):**
  ```json
  {
    "errors": [
      { "status": 404, "message": "Assessment not found" }
    ]
  }
  ```

---

### TC-ASM-012 — Delete assessment
- **Priority:** P1
- **Method / Path:** `DELETE /api/v1/assessments/:id`
- **Auth:** Bearer JWT
- **Precondition:** Use a disposable assessment id (create one dedicated for delete), not `$ASSESSMENT_ID` needed by later suites. Prefer an assessment with **no** sessions (model uses `dependent: :restrict_with_error`).
- **curl:**
  ```bash
  # create disposable then delete
  DISP=$(curl -s -X POST "$BASE/api/v1/assessments" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"assessment":{"name":"To Delete","time_limit_min":15,"language":"en"}}' \
    | jq -r .assessment.id)

  curl -i -X DELETE "$BASE/api/v1/assessments/$DISP" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `200`
- **Expected message:** `Assessment deleted`
- **Expected payload (validate):**
  ```json
  { "message": "Assessment deleted" }
  ```

---

### TC-ASM-013 — Delete assessment not found
- **Priority:** P2
- **Method / Path:** `DELETE /api/v1/assessments/:id`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i -X DELETE "$BASE/api/v1/assessments/999999" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `404`
- **Expected message:** `Assessment not found`
- **Expected payload (validate):**
  ```json
  {
    "errors": [
      { "status": 404, "message": "Assessment not found" }
    ]
  }
  ```

---

### TC-ASM-014 — Create assessment rejects missing token
- **Priority:** P0
- **Method / Path:** `POST /api/v1/assessments`
- **Auth:** none
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/assessments" \
    -H "Content-Type: application/json" \
    -H "X-Tenant-Scheme: $TENANT" \
    -d '{"assessment":{"name":"No Auth","time_limit_min":30}}'
  ```
- **Expected status:** `401`
- **Expected message:** `Missing token`
- **Expected payload (validate):**
  ```json
  {
    "errors": [
      { "status": 401, "message": "Missing token" }
    ]
  }
  ```
