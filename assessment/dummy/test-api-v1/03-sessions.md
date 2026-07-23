# 03 — Sessions

Requires `$TOKEN` and `$ASSESSMENT_ID` from prior suites.

---

### TC-SES-001 — Create session
- **Priority:** P0
- **Method / Path:** `POST /api/v1/assessments/:assessment_id/sessions`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/assessments/$ASSESSMENT_ID/sessions" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "session": {
        "candidate_id": "cand-001",
        "candidate_name": "Test Candidate"
      }
    }'
  ```
- **Expected status:** `201`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - Top-level keys: `session`, `invite_url`
  - `session` includes: `id`, `assessment_id`, `invite_token`, `invite_url`, `status`, `candidate_name`
  - `invite_url` is non-empty string
  ```json
  {
    "session": {
      "id": 1,
      "assessment_id": 1,
      "candidate_id": "cand-001",
      "candidate_name": "Test Candidate",
      "invite_token": "...",
      "invite_url": "...",
      "status": "...",
      "end_reason": null,
      "started_at": null,
      "ended_at": null,
      "duration_seconds": null,
      "created_at": "..."
    },
    "invite_url": "..."
  }
  ```
- **Save:** `$SESSION_ID` = `.session.id`, `$INVITE_TOKEN` = `.session.invite_token`

---

### TC-SES-002 — List sessions for assessment
- **Priority:** P0
- **Method / Path:** `GET /api/v1/assessments/:assessment_id/sessions`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/assessments/$ASSESSMENT_ID/sessions" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `200`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - Top-level key: `sessions` (array)
  - Contains an object with `id` == `$SESSION_ID`
  ```json
  {
    "sessions": [
      {
        "id": 1,
        "assessment_id": 1,
        "invite_token": "...",
        "status": "..."
      }
    ]
  }
  ```

---

### TC-SES-003 — List sessions for missing assessment
- **Priority:** P1
- **Method / Path:** `GET /api/v1/assessments/:assessment_id/sessions`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/assessments/999999/sessions" \
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

### TC-SES-004 — Get session by id
- **Priority:** P0
- **Method / Path:** `GET /api/v1/sessions/:id`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/sessions/$SESSION_ID" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `200`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - Top-level key: `session`
  - Nested `session.assessment` with `id`, `name`, `time_limit_min`
  ```json
  {
    "session": {
      "id": 1,
      "assessment_id": 1,
      "status": "...",
      "assessment": {
        "id": 1,
        "name": "...",
        "time_limit_min": 30
      }
    }
  }
  ```

---

### TC-SES-005 — Get session not found
- **Priority:** P1
- **Method / Path:** `GET /api/v1/sessions/:id`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/sessions/999999" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `404`
- **Expected message:** `Session not found`
- **Expected payload (validate):**
  ```json
  {
    "errors": [
      { "status": 404, "message": "Session not found" }
    ]
  }
  ```

---

### TC-SES-006 — Get coverage maps
- **Priority:** P1
- **Method / Path:** `GET /api/v1/sessions/:id/coverage`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/sessions/$SESSION_ID/coverage" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `200`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - Top-level keys: `skills`, `discovered`, `updated_at`
  - `skills` and `discovered` are arrays
  - Coverage items (when present) include: `id`, `skill_id`, `skill_label`, `is_discovered`, `state`, `probe_count`
  ```json
  {
    "skills": [],
    "discovered": [],
    "updated_at": null
  }
  ```

---

### TC-SES-007 — Get transcript
- **Priority:** P1
- **Method / Path:** `GET /api/v1/sessions/:id/transcript`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/sessions/$SESSION_ID/transcript?from_turn=0" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `200`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - Top-level keys: `turns`, `total`
  - `turns` is array; `total` is integer
  - Turn items include: `id`, `turn_number`, `speaker`, `text`, `audio_start_ms`, `audio_end_ms`, `created_at`
  ```json
  {
    "turns": [],
    "total": 0
  }
  ```

---

### TC-SES-008 — Candidate info (public invite token)
- **Priority:** P0
- **Method / Path:** `GET /api/v1/sessions/:token/candidate`
- **Auth:** invite token in path (no JWT)
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/sessions/$INVITE_TOKEN/candidate"
  ```
- **Expected status:** `200`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - Keys: `session_id`, `role_title`, `time_limit_min`, `session_status`
  - `session_id` == `$SESSION_ID`
  ```json
  {
    "session_id": 1,
    "role_title": "...",
    "time_limit_min": 30,
    "session_status": "..."
  }
  ```

---

### TC-SES-009 — Candidate info invalid token
- **Priority:** P1
- **Method / Path:** `GET /api/v1/sessions/:token/candidate`
- **Auth:** invite token
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/sessions/invalid-token-xyz/candidate"
  ```
- **Expected status:** `404`
- **Expected message:** `Invalid or expired invite token`
- **Expected payload (validate):**
  ```json
  {
    "errors": [
      { "status": 404, "message": "Invalid or expired invite token" }
    ]
  }
  ```

---

### TC-SES-010 — End session (assessor)
- **Priority:** P0
- **Method / Path:** `POST /api/v1/sessions/:id/end_session`
- **Auth:** Bearer JWT
- **Precondition:** Session is not already ended. Prefer a dedicated session if you still need an active one for other flows.
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/sessions/$SESSION_ID/end_session" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "session": { "reason": "manual_assessor" }
    }'
  ```
- **Expected status:** `200`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - Top-level key: `session`
  - `session.end_reason` == `"manual_assessor"`
  - `session.ended_at` is non-null
  ```json
  {
    "session": {
      "id": 1,
      "status": "...",
      "end_reason": "manual_assessor",
      "ended_at": "..."
    }
  }
  ```

---

### TC-SES-011 — End session invalid reason
- **Priority:** P1
- **Method / Path:** `POST /api/v1/sessions/:id/end_session`
- **Auth:** Bearer JWT
- **Precondition:** Create a fresh (not ended) session for this case
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/sessions/$FRESH_SESSION_ID/end_session" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "session": { "reason": "not_a_valid_reason" }
    }'
  ```
- **Expected status:** `422`
- **Expected message:** `Invalid end reason`
- **Expected payload (validate):**
  ```json
  {
    "errors": [
      { "status": 422, "message": "Invalid end reason" }
    ]
  }
  ```

---

### TC-SES-012 — End session already ended
- **Priority:** P1
- **Method / Path:** `POST /api/v1/sessions/:id/end_session`
- **Auth:** Bearer JWT
- **Precondition:** Session from TC-SES-010 already ended
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/sessions/$SESSION_ID/end_session" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "session": { "reason": "manual_assessor" }
    }'
  ```
- **Expected status:** `422`
- **Expected message:** `Session is already ended`
- **Expected payload (validate):**
  ```json
  {
    "errors": [
      { "status": 422, "message": "Session is already ended" }
    ]
  }
  ```

---

### TC-SES-013 — Audio complete with invalid token
- **Priority:** P1
- **Method / Path:** `POST /api/v1/sessions/:token/audio_complete`
- **Auth:** invite token
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/sessions/invalid-token-xyz/audio_complete"
  ```
- **Expected status:** `404`
- **Expected message:** `Invalid or expired invite token`
- **Expected payload (validate):**
  ```json
  {
    "errors": [
      { "status": 404, "message": "Invalid or expired invite token" }
    ]
  }
  ```

---

### TC-SES-014 — Audio complete when session already ended (idempotent)
- **Priority:** P1
- **Method / Path:** `POST /api/v1/sessions/:token/audio_complete`
- **Auth:** invite token
- **Precondition:** Session already ended; use its `invite_token`
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/sessions/$INVITE_TOKEN/audio_complete"
  ```
- **Expected status:** `200`
- **Expected message:** `Session already ended`
- **Expected payload (validate):**
  - `ended` == `true`
  - `message` == `"Session already ended"`
  ```json
  {
    "ended": true,
    "message": "Session already ended"
  }
  ```

---

### TC-SES-015 — Audio complete ends active session
- **Priority:** P1
- **Method / Path:** `POST /api/v1/sessions/:token/audio_complete`
- **Auth:** invite token
- **Precondition:** Fresh active session (not ended). Note: production flow expects WS `preparing_to_end` first; endpoint still calls EndHandler with `all_covered`.
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/sessions/$ACTIVE_INVITE_TOKEN/audio_complete"
  ```
- **Expected status:** `200`
- **Expected message:** `Session ended`
- **Expected payload (validate):**
  ```json
  {
    "ended": true,
    "message": "Session ended"
  }
  ```
