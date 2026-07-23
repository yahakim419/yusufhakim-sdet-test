# 04 — Portfolios

Requires `$TOKEN`, `$SESSION_ID` (preferably ended with portfolio generation possible), and `$VACANCY_ID` from [05-vacancies.md](05-vacancies.md).

Sidekiq must be running for generation workers. Poll portfolio until `generation_status` is `complete` or `failed` before export/fitgap happy paths.

---

### TC-PF-001 — Get portfolio while generating / missing
- **Priority:** P1
- **Method / Path:** `GET /api/v1/sessions/:id/portfolio`
- **Auth:** Bearer JWT
- **Precondition:** Portfolio missing or `generation_status` is generating/pending
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/sessions/$SESSION_ID/portfolio" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `202`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - `status` == `"generating"`
  ```json
  { "status": "generating" }
  ```

---

### TC-PF-002 — Get portfolio when ready
- **Priority:** P0
- **Method / Path:** `GET /api/v1/sessions/:id/portfolio`
- **Auth:** Bearer JWT
- **Precondition:** Portfolio `generation_status` is complete (ready for use)
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/sessions/$SESSION_ID/portfolio" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `200`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - Top-level key: `portfolio`
  - `portfolio` keys: `id`, `session_id`, `candidate_id`, `generation_status`, `generated_at`, `generation_error`, `skills`, `overrides`
  - `skills[]` include: `id`, `skill_id`, `skill_label`, `ai_level`, `ai_confidence`, `evidence`, `competency_summary`
  ```json
  {
    "portfolio": {
      "id": 1,
      "session_id": 1,
      "generation_status": "complete",
      "skills": [],
      "overrides": []
    }
  }
  ```
- **Save:** `$PORTFOLIO_ID`, `$PORTFOLIO_SKILL_ID` from first skill if present

---

### TC-PF-003 — Get portfolio when failed
- **Priority:** P1
- **Method / Path:** `GET /api/v1/sessions/:id/portfolio`
- **Auth:** Bearer JWT
- **Precondition:** Portfolio `generation_status` is failed
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/sessions/$FAILED_SESSION_ID/portfolio" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `200`
- **Expected message:** `n/a` (error text is in `error` field, not envelope)
- **Expected payload (validate):**
  - Keys: `portfolio`, `error`
  - `error` is non-empty string (generation error)
  - `portfolio.generation_status` reflects failed
  ```json
  {
    "portfolio": {
      "id": 1,
      "generation_status": "failed",
      "generation_error": "..."
    },
    "error": "..."
  }
  ```

---

### TC-PF-004 — Regenerate portfolio when failed
- **Priority:** P1
- **Method / Path:** `POST /api/v1/sessions/:id/portfolio/regenerate`
- **Auth:** Bearer JWT
- **Precondition:** Portfolio status is `failed`
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/sessions/$FAILED_SESSION_ID/portfolio/regenerate" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `200`
- **Expected message:** `Portfolio generation queued`
- **Expected payload (validate):**
  - Keys: `message`, `portfolio`
  ```json
  {
    "message": "Portfolio generation queued",
    "portfolio": {
      "id": 1,
      "generation_status": "pending"
    }
  }
  ```

---

### TC-PF-005 — Regenerate portfolio rejected when not failed
- **Priority:** P1
- **Method / Path:** `POST /api/v1/sessions/:id/portfolio/regenerate`
- **Auth:** Bearer JWT
- **Precondition:** Portfolio exists and status is not `failed`
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/sessions/$SESSION_ID/portfolio/regenerate" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `422`
- **Expected message:** `Portfolio can only be regenerated when status is 'failed'`
- **Expected payload (validate):**
  ```json
  {
    "errors": [
      {
        "status": 422,
        "message": "Portfolio can only be regenerated when status is 'failed'"
      }
    ]
  }
  ```

---

### TC-PF-006 — Regenerate when no portfolio
- **Priority:** P2
- **Method / Path:** `POST /api/v1/sessions/:id/portfolio/regenerate`
- **Auth:** Bearer JWT
- **Precondition:** Session with no portfolio record
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/sessions/$NO_PORTFOLIO_SESSION_ID/portfolio/regenerate" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `404`
- **Expected message:** `No portfolio found for this session`
- **Expected payload (validate):**
  ```json
  {
    "errors": [
      { "status": 404, "message": "No portfolio found for this session" }
    ]
  }
  ```

---

### TC-PF-007 — Fit/gap missing vacancy_id
- **Priority:** P1
- **Method / Path:** `POST /api/v1/portfolios/:id/fitgap`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/portfolios/$PORTFOLIO_ID/fitgap" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{}'
  ```
- **Expected status:** `422`
- **Expected message:** `vacancy_id is required`
- **Expected payload (validate):**
  ```json
  {
    "errors": [
      { "status": 422, "message": "vacancy_id is required" }
    ]
  }
  ```

---

### TC-PF-008 — Fit/gap vacancy not found
- **Priority:** P1
- **Method / Path:** `POST /api/v1/portfolios/:id/fitgap`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/portfolios/$PORTFOLIO_ID/fitgap" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"vacancy_id": 999999}'
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

### TC-PF-009 — Fit/gap queue generation (no cache)
- **Priority:** P0
- **Method / Path:** `POST /api/v1/portfolios/:id/fitgap`
- **Auth:** Bearer JWT
- **Precondition:** Portfolio complete; no existing FitGapReport for this vacancy
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/portfolios/$PORTFOLIO_ID/fitgap" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"fitgap\":{\"vacancy_id\":$VACANCY_ID}}"
  ```
- **Expected status:** `202`
- **Expected message:** `Fit/gap report generation queued`
- **Expected payload (validate):**
  ```json
  {
    "status": "generating",
    "message": "Fit/gap report generation queued"
  }
  ```

---

### TC-PF-010 — Fit/gap returns cached report
- **Priority:** P0
- **Method / Path:** `POST /api/v1/portfolios/:id/fitgap`
- **Auth:** Bearer JWT
- **Precondition:** FitGapReport already exists for portfolio + vacancy
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/portfolios/$PORTFOLIO_ID/fitgap" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"vacancy_id\":$VACANCY_ID}"
  ```
- **Expected status:** `200`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - Top-level key: `report`
  - Report keys: `id`, `portfolio_id`, `vacancy_id`, `skill_comparisons`, `culture_narrative`, `overall_narrative`, `generated_at`
  ```json
  {
    "report": {
      "id": 1,
      "portfolio_id": 1,
      "vacancy_id": 1,
      "skill_comparisons": [],
      "culture_narrative": "...",
      "overall_narrative": "...",
      "generated_at": "..."
    }
  }
  ```

---

### TC-PF-011 — Get fit/gap report
- **Priority:** P0
- **Method / Path:** `GET /api/v1/portfolios/:id/fitgap/:vacancy_id`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/portfolios/$PORTFOLIO_ID/fitgap/$VACANCY_ID" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `200`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - Same `report` shape as TC-PF-010
  ```json
  {
    "report": {
      "id": 1,
      "portfolio_id": 1,
      "vacancy_id": 1
    }
  }
  ```

---

### TC-PF-012 — Get fit/gap report not found
- **Priority:** P1
- **Method / Path:** `GET /api/v1/portfolios/:id/fitgap/:vacancy_id`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/portfolios/$PORTFOLIO_ID/fitgap/999999" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `404`
- **Expected message:** `Fit/gap report not found`
- **Expected payload (validate):**
  ```json
  {
    "errors": [
      { "status": 404, "message": "Fit/gap report not found" }
    ]
  }
  ```

---

### TC-PF-013 — Regenerate fit/gap
- **Priority:** P1
- **Method / Path:** `POST /api/v1/portfolios/:id/regenerate_fitgap`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/portfolios/$PORTFOLIO_ID/regenerate_fitgap" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"vacancy_id\":$VACANCY_ID}"
  ```
- **Expected status:** `202`
- **Expected message:** `Fit/gap report regeneration queued`
- **Expected payload (validate):**
  ```json
  {
    "status": "generating",
    "message": "Fit/gap report regeneration queued"
  }
  ```

---

### TC-PF-014 — Export portfolio JSON
- **Priority:** P0
- **Method / Path:** `GET /api/v1/portfolios/:id/export`
- **Auth:** Bearer JWT
- **Precondition:** Portfolio complete
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/portfolios/$PORTFOLIO_ID/export?format=json&vacancy_id=$VACANCY_ID" \
    -H "Authorization: Bearer $TOKEN" \
    -o portfolio-export.json
  ```
- **Expected status:** `200`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - `Content-Type: application/json`
  - `Content-Disposition` attachment filename contains `portfolio-`
  - Body keys: `exported_at`, `portfolio`; optional `fit_gap_report`
  ```json
  {
    "exported_at": "...",
    "portfolio": { "id": 1, "skills": [], "overrides": [] },
    "fit_gap_report": null
  }
  ```

---

### TC-PF-015 — Export invalid format
- **Priority:** P1
- **Method / Path:** `GET /api/v1/portfolios/:id/export`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/portfolios/$PORTFOLIO_ID/export?format=xml" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `422`
- **Expected message:** `Format must be 'pdf' or 'json'`
- **Expected payload (validate):**
  ```json
  {
    "errors": [
      { "status": 422, "message": "Format must be 'pdf' or 'json'" }
    ]
  }
  ```

---

### TC-PF-016 — Override portfolio skill
- **Priority:** P0
- **Method / Path:** `POST /api/v1/portfolio_skills/:id/override`
- **Auth:** Bearer JWT
- **Precondition:** `$PORTFOLIO_SKILL_ID` from a complete portfolio
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/portfolio_skills/$PORTFOLIO_SKILL_ID/override" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "override": {
        "override_level": 4,
        "assessor_notes": "Strong evidence in transcript"
      }
    }'
  ```
- **Expected status:** `201` (first create) or `200` (update existing)
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - Top-level key: `override`
  - Keys: `id`, `portfolio_skill_id`, `ai_level`, `override_level`, `assessor_notes`, `overridden_by`, `overridden_at`
  - `override_level` == `4`
  ```json
  {
    "override": {
      "id": 1,
      "portfolio_skill_id": 1,
      "ai_level": 3,
      "override_level": 4,
      "assessor_notes": "Strong evidence in transcript",
      "overridden_by": 1,
      "overridden_at": "..."
    }
  }
  ```

---

### TC-PF-017 — Override portfolio skill not found
- **Priority:** P1
- **Method / Path:** `POST /api/v1/portfolio_skills/:id/override`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/portfolio_skills/999999/override" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "override": { "override_level": 2, "assessor_notes": "n/a" }
    }'
  ```
- **Expected status:** `404`
- **Expected message:** `Portfolio skill not found`
- **Expected payload (validate):**
  ```json
  {
    "errors": [
      { "status": 404, "message": "Portfolio skill not found" }
    ]
  }
  ```

---

### TC-PF-018 — Portfolio not found on fitgap
- **Priority:** P2
- **Method / Path:** `POST /api/v1/portfolios/:id/fitgap`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/portfolios/999999/fitgap" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"vacancy_id\":$VACANCY_ID}"
  ```
- **Expected status:** `404`
- **Expected message:** `Portfolio not found`
- **Expected payload (validate):**
  ```json
  {
    "errors": [
      { "status": 404, "message": "Portfolio not found" }
    ]
  }
  ```
