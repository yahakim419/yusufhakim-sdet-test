# 01 — Auth & Health

Setup: see [README.md](README.md). No JWT required unless noted.

Evidence: `api/config/routes.rb`, `api/app/controllers/api/v1/authentication_controller.rb`, `api/app/auth/authorize_api_request.rb`, `api/app/lib/message.rb`, `api/config/initializers/rack_attack.rb`, `api/app/controllers/application_controller.rb`.

---

### TC-AUTH-001 — Root health check
- **Priority:** P0
- **Method / Path:** `GET /health`
- **Auth:** none
- **curl:**
  ```bash
  curl -i "$BASE/health"
  ```
- **Expected status:** `200`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - Top-level keys: `status`
  - `status` is string `"ok"`
  ```json
  { "status": "ok" }
  ```

---

### TC-AUTH-002 — API v1 health check
- **Priority:** P0
- **Method / Path:** `GET /api/v1/health`
- **Auth:** none
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/health"
  ```
- **Expected status:** `200`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  ```json
  { "status": "ok" }
  ```

---

### TC-AUTH-003 — Speed test returns received bytes
- **Priority:** P2
- **Method / Path:** `POST /api/v1/speed_test`
- **Auth:** none
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/speed_test" \
    -H "Content-Type: application/json" \
    -d '{"ping":true}'
  ```
- **Expected status:** `200`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - Top-level keys: `received_bytes`
  - `received_bytes` is integer equal to request `Content-Length`
  ```json
  { "received_bytes": 13 }
  ```

---

### TC-AUTH-004 — Speed test with empty body
- **Priority:** P2
- **Method / Path:** `POST /api/v1/speed_test`
- **Auth:** none
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/speed_test" \
    -H "Content-Type: application/json" \
    -d ''
  ```
- **Expected status:** `200`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - `received_bytes` is integer (0 when no body / Content-Length 0)
  ```json
  { "received_bytes": 0 }
  ```

---

### TC-AUTH-005 — Admin login success
- **Priority:** P0
- **Method / Path:** `POST /api/v1/auth/login`
- **Auth:** none (provide valid admin credentials)
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/auth/login" \
    -H "Content-Type: application/json" \
    -H "X-Tenant-Scheme: $TENANT" \
    -d "{\"email\":\"$EMAIL\",\"password\":\"$PASS\"}"
  ```
- **Expected status:** `200`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - Top-level keys: `token`, `user`
  - `token` is non-empty string (JWT)
  - `user.id` integer, `user.email` string, `user.role` is `"admin"`
  ```json
  {
    "token": "<jwt>",
    "user": {
      "id": 1,
      "email": "admin@example.com",
      "role": "admin"
    }
  }
  ```
- **Save:** `$TOKEN` from `.token` for later suites

---

### TC-AUTH-006 — Login fails with wrong password
- **Priority:** P0
- **Method / Path:** `POST /api/v1/auth/login`
- **Auth:** none
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/auth/login" \
    -H "Content-Type: application/json" \
    -H "X-Tenant-Scheme: $TENANT" \
    -d "{\"email\":\"$EMAIL\",\"password\":\"wrong-password\"}"
  ```
- **Expected status:** `401`
- **Expected message:** `Invalid email or password`
- **Expected payload (validate):**
  - `errors` array length >= 1
  - `errors[0].status` == `401`
  - `errors[0].message` == `"Invalid email or password"`
  ```json
  {
    "errors": [
      { "status": 401, "message": "Invalid email or password" }
    ]
  }
  ```

---

### TC-AUTH-007 — Login fails for unknown email
- **Priority:** P1
- **Method / Path:** `POST /api/v1/auth/login`
- **Auth:** none
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/auth/login" \
    -H "Content-Type: application/json" \
    -H "X-Tenant-Scheme: $TENANT" \
    -d '{"email":"nobody@example.com","password":"anything"}'
  ```
- **Expected status:** `401`
- **Expected message:** `Invalid email or password`
- **Expected payload (validate):**
  ```json
  {
    "errors": [
      { "status": 401, "message": "Invalid email or password" }
    ]
  }
  ```

---

### TC-AUTH-008 — Login fails for non-admin user
- **Priority:** P0
- **Method / Path:** `POST /api/v1/auth/login`
- **Auth:** none
- **Precondition:** A user exists with valid password but `role != 'admin'` (e.g. student / assessor)
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/auth/login" \
    -H "Content-Type: application/json" \
    -H "X-Tenant-Scheme: $TENANT" \
    -d "{\"email\":\"$STUDENT_EMAIL\",\"password\":\"$STUDENT_PASS\"}"
  ```
- **Expected status:** `401`
- **Expected message:** `Invalid email or password`
- **Expected payload (validate):**
  ```json
  {
    "errors": [
      { "status": 401, "message": "Invalid email or password" }
    ]
  }
  ```

---

### TC-AUTH-009 — Protected endpoint rejects missing token
- **Priority:** P0
- **Method / Path:** `GET /api/v1/assessments`
- **Auth:** none (intentionally omit Bearer)
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/assessments" \
    -H "X-Tenant-Scheme: $TENANT"
  ```
- **Expected status:** `401`
- **Expected message:** `Missing token`
- **Expected payload (validate):**
  - Response is an error envelope, not an assessments list
  - Must **not** contain top-level `assessments` array with data
  ```json
  {
    "errors": [
      { "status": 401, "message": "Missing token" }
    ]
  }
  ```

---

### TC-AUTH-010 — Protected endpoint rejects invalid JWT
- **Priority:** P0
- **Method / Path:** `GET /api/v1/assessments`
- **Auth:** Bearer with malformed/invalid token
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/assessments" \
    -H "Authorization: Bearer not-a-valid-jwt" \
    -H "X-Tenant-Scheme: $TENANT"
  ```
- **Expected status:** `401`
- **Expected message:** (JWT gem decode error text; assert non-empty `errors[0].message`)
- **Expected payload (validate):**
  - `errors[0].status` == `401`
  - Must **not** contain top-level `assessments` with data
  ```json
  {
    "errors": [
      { "status": 401, "message": "<jwt decode error>" }
    ]
  }
  ```

---

### TC-AUTH-011 — Protected endpoint rejects when tenant cannot be resolved
- **Priority:** P1
- **Method / Path:** `GET /api/v1/assessments`
- **Auth:** Bearer JWT whose `scheme` claim does not match any organization, and omit `X-Tenant-Scheme`
- **Precondition:** Use a JWT with an unknown `scheme`, or call without a resolvable tenant header when JWT has no valid scheme
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/assessments" \
    -H "Authorization: Bearer $TOKEN_UNKNOWN_SCHEME"
  ```
- **Expected status:** `403`
- **Expected message:** `Tenant not found. Ensure the JWT scheme claim is valid.`
- **Expected payload (validate):**
  ```json
  {
    "errors": [
      {
        "status": 403,
        "message": "Tenant not found. Ensure the JWT scheme claim is valid."
      }
    ]
  }
  ```

---

### TC-AUTH-012 — Login rate limit exceeded
- **Priority:** P2
- **Method / Path:** `POST /api/v1/auth/login`
- **Auth:** none
- **Precondition:** Redis available for Rack::Attack. Send **6** POSTs to `/api/v1/auth/login` from the same IP within 1 minute (limit is 5/min).
- **curl:**
  ```bash
  for i in 1 2 3 4 5 6; do
    curl -i -X POST "$BASE/api/v1/auth/login" \
      -H "Content-Type: application/json" \
      -H "X-Tenant-Scheme: $TENANT" \
      -d '{"email":"nobody@example.com","password":"x"}'
  done
  ```
- **Expected status:** `429` on the 6th request
- **Expected message:** `Too many requests. Please try again later.`
- **Expected payload (validate):**
  - Top-level key is `error` (not `errors`)
  ```json
  { "error": "Too many requests. Please try again later." }
  ```