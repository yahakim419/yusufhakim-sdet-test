# 05 — Vacancies

Requires `$TOKEN` from [01-auth-and-health.md](01-auth-and-health.md).

---

### TC-VAC-001 — List vacancies (paginated)
- **Priority:** P0
- **Method / Path:** `GET /api/v1/vacancies`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/vacancies?page=1&per_page=20" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `200`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - Top-level keys: `vacancies`, `meta`
  - `meta` has `current_page`, `total_pages`, `total_count`, `per_page`
  - Vacancy summary keys: `id`, `role_title`, `culture_dimensions`, `competency_expectations`, `created_by`, `created_at`, `updated_at`
  ```json
  {
    "vacancies": [
      {
        "id": 1,
        "role_title": "...",
        "created_by": 1,
        "created_at": "...",
        "updated_at": "..."
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

### TC-VAC-002 — Create vacancy
- **Priority:** P0
- **Method / Path:** `POST /api/v1/vacancies`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/vacancies" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "vacancy": {
        "role_title": "Senior Frontend Engineer",
        "culture_dimensions": "Collaborative, ownership-driven",
        "competency_expectations": "Strong React and system design",
        "vacancy_skills_attributes": [
          {
            "skill_id": "SK-ENG-001",
            "skill_label": "React / Frontend Development Core",
            "expected_level": 4
          }
        ]
      }
    }'
  ```
- **Expected status:** `201`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - Top-level key: `vacancy`
  - `vacancy.role_title` == `"Senior Frontend Engineer"`
  - `vacancy.skills` is array with at least one skill including `skill_id`, `expected_level`, and optional `l1_anchor`…`l5_anchor`
  ```json
  {
    "vacancy": {
      "id": 1,
      "role_title": "Senior Frontend Engineer",
      "culture_dimensions": "Collaborative, ownership-driven",
      "competency_expectations": "Strong React and system design",
      "created_by": 1,
      "skills": [
        {
          "id": 1,
          "skill_id": "SK-ENG-001",
          "skill_label": "React / Frontend Development Core",
          "expected_level": 4,
          "l1_anchor": "...",
          "l2_anchor": "..."
        }
      ]
    }
  }
  ```
- **Save:** `$VACANCY_ID` from `.vacancy.id`

---

### TC-VAC-003 — Create vacancy validation error (missing role_title)
- **Priority:** P1
- **Method / Path:** `POST /api/v1/vacancies`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/vacancies" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "vacancy": {
        "culture_dimensions": "x"
      }
    }'
  ```
- **Expected status:** `422`
- **Expected message:** (presence validation; typically `Role title can't be blank`)
- **Expected payload (validate):**
  - `errors[0].status` == `422`
  - `errors[0].message` non-empty
  ```json
  {
    "errors": [
      { "status": 422, "message": "Role title can't be blank" }
    ]
  }
  ```

---

### TC-VAC-004 — Get vacancy by id
- **Priority:** P0
- **Method / Path:** `GET /api/v1/vacancies/:id`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/vacancies/$VACANCY_ID" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `200`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - Top-level key: `vacancy` with nested `skills` array
  ```json
  {
    "vacancy": {
      "id": 1,
      "role_title": "Senior Frontend Engineer",
      "skills": []
    }
  }
  ```

---

### TC-VAC-005 — Get vacancy not found
- **Priority:** P1
- **Method / Path:** `GET /api/v1/vacancies/:id`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/vacancies/999999" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `404`
- **Expected message:** `Vacancy not found`
- **Expected payload (validate):**
  ```json
  {
    "errors": [
      { "status": 404, "message": "Vacancy not found" }
    ]
  }
  ```

---

### TC-VAC-006 — Update vacancy
- **Priority:** P0
- **Method / Path:** `PUT /api/v1/vacancies/:id`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i -X PUT "$BASE/api/v1/vacancies/$VACANCY_ID" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "vacancy": {
        "role_title": "Staff Frontend Engineer",
        "culture_dimensions": "High ownership",
        "competency_expectations": "Mentorship + architecture"
      }
    }'
  ```
- **Expected status:** `200`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - `vacancy.role_title` == `"Staff Frontend Engineer"`
  ```json
  {
    "vacancy": {
      "id": 1,
      "role_title": "Staff Frontend Engineer",
      "skills": []
    }
  }
  ```

---

### TC-VAC-007 — Delete vacancy
- **Priority:** P1
- **Method / Path:** `DELETE /api/v1/vacancies/:id`
- **Auth:** Bearer JWT
- **Precondition:** Disposable vacancy (do not delete `$VACANCY_ID` needed by portfolio fit/gap)
- **curl:**
  ```bash
  DISP=$(curl -s -X POST "$BASE/api/v1/vacancies" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"vacancy":{"role_title":"Temp Delete Me"}}' \
    | jq -r .vacancy.id)

  curl -i -X DELETE "$BASE/api/v1/vacancies/$DISP" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `200`
- **Expected message:** `Vacancy deleted`
- **Expected payload (validate):**
  ```json
  { "message": "Vacancy deleted" }
  ```

---

### TC-VAC-008 — Delete vacancy not found
- **Priority:** P2
- **Method / Path:** `DELETE /api/v1/vacancies/:id`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i -X DELETE "$BASE/api/v1/vacancies/999999" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `404`
- **Expected message:** `Vacancy not found`
- **Expected payload (validate):**
  ```json
  {
    "errors": [
      { "status": 404, "message": "Vacancy not found" }
    ]
  }
  ```
