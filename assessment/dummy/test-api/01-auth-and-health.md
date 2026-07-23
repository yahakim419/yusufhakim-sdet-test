# 01 — Auth & Health

Setup: see [README.md](../test-api-v1/README.md). No JWT required unless noted.

Admin user is **not** created by `rails db:seed` — create an admin out-of-band before login cases.

Do **not** assert `Content-Type: application/json` on health responses (Rack procs omit it).

---

### TC-HEALTH-001 — GET /health
- **Priority:** P0
- **Method / Path:** `GET /health`
- **Auth:** none
- **Precondition:** none
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
- **Expected state change:** `n/a`

---

### TC-HEALTH-002 — GET /api/v1/health
- **Priority:** P0
- **Method / Path:** `GET /api/v1/health`
- **Auth:** none
- **Precondition:** none
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/health"
  ```
- **Expected status:** `200`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - Top-level keys: `status`
  - `status` is string `"ok"`
  ```json
  { "status": "ok" }
  ```
- **Expected state change:** `n/a`

---

### TC-SPEED-001 — Speed test with payload
- **Priority:** P2
- **Method / Path:** `POST /api/v1/speed_test`
- **Auth:** none
- **Precondition:** none
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
  - `received_bytes` is integer equal to request `Content-Length` (for `{"ping":true}` → `13`)
  - Response `Content-Type` is `application/json`
  ```json
  { "received_bytes": 13 }
  ```
- **Expected state change:** `n/a`

---

### TC-SPEED-002 — Speed test without body
- **Priority:** P2
- **Method / Path:** `POST /api/v1/speed_test`
- **Auth:** none
- **Precondition:** none
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/speed_test"
  ```
- **Expected status:** `200`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - Top-level keys: `received_bytes`
  - `received_bytes` is integer `0` when `CONTENT_LENGTH` is missing
  - Response `Content-Type` is `application/json`
  ```json
  { "received_bytes": 0 }
  ```
- **Expected state change:** `n/a`

---

### TC-AUTH-001 — Valid admin login
- **Priority:** P0
- **Method / Path:** `POST /api/v1/auth/login`
- **Auth:** none (provide valid admin credentials)
- **Precondition:** An admin user exists (`role == 'admin'`) with known email/password. Seeds do not create users.
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
- **Expected state change:** `n/a`
- **Save:** `$TOKEN` from `.token` for later suites

---

### TC-AUTH-002 — Invalid password
- **Priority:** P0
- **Method / Path:** `POST /api/v1/auth/login`
- **Auth:** none
- **Precondition:** Admin email `$EMAIL` exists; password used is incorrect
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
- **Expected state change:** `n/a`

---

### TC-AUTH-003 — Unknown email
- **Priority:** P1
- **Method / Path:** `POST /api/v1/auth/login`
- **Auth:** none
- **Precondition:** Email is not present in `users`
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
- **Expected state change:** `n/a`

---

### TC-AUTH-004 — Valid non-admin login
- **Priority:** P0
- **Method / Path:** `POST /api/v1/auth/login`
- **Auth:** none
- **Precondition:** A user exists with valid password and `role == 'user'` (not `admin`). `User::ROLES` is `admin` | `user`.
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/auth/login" \
    -H "Content-Type: application/json" \
    -H "X-Tenant-Scheme: $TENANT" \
    -d "{\"email\":\"$USER_EMAIL\",\"password\":\"$USER_PASS\"}"
  ```
- **Expected status:** `401`
- **Expected message:** `Invalid email or password`
- **Expected payload (validate):**
  - Same envelope/message as invalid credentials (no distinct “forbidden role” status on login)
  ```json
  {
    "errors": [
      { "status": 401, "message": "Invalid email or password" }
    ]
  }
  ```
- **Expected state change:** `n/a`

---

### TC-AUTH-005 — Empty login body
- **Priority:** P1
- **Method / Path:** `POST /api/v1/auth/login`
- **Auth:** none
- **Precondition:** none
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/auth/login" \
    -H "Content-Type: application/json" \
    -H "X-Tenant-Scheme: $TENANT" \
    -d '{}'
  ```
- **Expected status:** `401`
- **Expected message:** `Invalid email or password`
- **Expected payload (validate):**
  - Missing/empty credentials are **not** enforced as `422`
  ```json
  {
    "errors": [
      { "status": 401, "message": "Invalid email or password" }
    ]
  }
  ```
- **Expected state change:** `n/a`

---

### TC-AUTH-006 — Malformed JSON
- **Priority:** P1
- **Method / Path:** `POST /api/v1/auth/login`
- **Auth:** none
- **Precondition:** none
- **curl:**
  ```bash
  curl -i -X POST "$BASE/api/v1/auth/login" \
    -H "Content-Type: application/json" \
    -H "X-Tenant-Scheme: $TENANT" \
    -d '{"email":'
  ```
- **Expected status:** `500`
- **Expected message:** `Error occurred while parsing request parameters`
- **Expected payload (validate):**
  - `errors` array length >= 1
  - `errors[0].status` == `500`
  - `errors[0].message` == `"Error occurred while parsing request parameters"`
  ```json
  {
    "errors": [
      {
        "status": 500,
        "message": "Error occurred while parsing request parameters"
      }
    ]
  }
  ```
- **Expected state change:** `n/a`

---

### TC-AUTH-007 — Login rate limit exceeded
- **Priority:** P1
- **Method / Path:** `POST /api/v1/auth/login`
- **Auth:** none
- **Precondition:** Redis available for Rack::Attack. From a single client IP, issue more than **5** `POST`s to `/api/v1/auth/login` within one minute (reset throttle state between runs if needed).
- **curl:**
  ```bash
  for i in 1 2 3 4 5 6; do
    curl -i -X POST "$BASE/api/v1/auth/login" \
      -H "Content-Type: application/json" \
      -H "X-Tenant-Scheme: $TENANT" \
      -d '{"email":"rate@example.com","password":"x"}'
  done
  ```
- **Expected status:** `429` (on the over-limit request)
- **Expected message:** `Too many requests. Please try again later.`
- **Expected payload (validate):**
  - Body uses `{ "error": "..." }` — **not** the standard `errors[]` envelope
  ```json
  { "error": "Too many requests. Please try again later." }
  ```
- **Expected state change:** `n/a`

---

### TC-AUTH-008 — Missing Bearer token
- **Priority:** P0
- **Method / Path:** `GET /api/v1/assessments`
- **Auth:** none (intentionally omit Bearer)
- **Precondition:** none (auth-gate smoke only; list success is out of suite scope)
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/assessments" \
    -H "X-Tenant-Scheme: $TENANT"
  ```
- **Expected status:** `401`
- **Expected message:** `Missing token`
- **Expected payload (validate):**
  - Error envelope, not an assessments list
  - Must **not** contain a successful assessments collection payload
  ```json
  {
    "errors": [
      { "status": 401, "message": "Missing token" }
    ]
  }
  ```
- **Expected state change:** `n/a`

---

### TC-AUTH-009 — Invalid JWT
- **Priority:** P0
- **Method / Path:** `GET /api/v1/assessments`
- **Auth:** Bearer with invalid/unreadable JWT
- **Precondition:** none
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/assessments" \
    -H "Authorization: Bearer not-a-jwt" \
    -H "X-Tenant-Scheme: $TENANT"
  ```
- **Expected status:** `401`
- **Expected message:** non-empty JWT decode error message (from `JWT::DecodeError`; do not assume `Message.invalid_token`)
- **Expected payload (validate):**
  - `errors` array length >= 1
  - `errors[0].status` == `401`
  - `errors[0].message` is present and non-empty
  - Response is not an assessments list
  ```json
  {
    "errors": [
      { "status": 401, "message": "<jwt-decode-error>" }
    ]
  }
  ```
- **Expected state change:** `n/a`

---

### TC-AUTH-010 — Wrong role
- **Priority:** P0
- **Method / Path:** `GET /api/v1/assessments`
- **Auth:** Bearer JWT whose `role` claim is not in the assessor group (`admin` | `assessor`)
- **Precondition:** A validly signed JWT exists with `role` = `"user"` (login only issues `admin`; mint a token with `SECRET_KEY_BASE` for this case). Include a resolvable tenant (`scheme` claim and/or `X-Tenant-Scheme: $TENANT`) so the failure is role-based, not tenant-based.
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/assessments" \
    -H "Authorization: Bearer $USER_ROLE_TOKEN" \
    -H "X-Tenant-Scheme: $TENANT"
  ```
- **Expected status:** `403`
- **Expected message:** `Unauthorized request`
- **Expected payload (validate):**
  ```json
  {
    "errors": [
      { "status": 403, "message": "Unauthorized request" }
    ]
  }
  ```
- **Expected state change:** `n/a`

---

### TC-AUTH-011 — Tenant not found
- **Priority:** P0
- **Method / Path:** `GET /api/v1/assessments`
- **Auth:** Bearer JWT with valid signature and assessor-allowed role (`admin`), but unresolved tenant
- **Precondition:** JWT `scheme` claim does not resolve to an organization, and `X-Tenant-Scheme` is omitted or also unresolvable (middleware cannot identify org). Token role must be allowed so failure is `require_tenant!`, not role check.
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
- **Expected state change:** `n/a`
