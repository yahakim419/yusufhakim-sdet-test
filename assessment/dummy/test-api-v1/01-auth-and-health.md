# 01 — Auth & Health

Setup: see [README.md](README.md). No JWT required unless noted.

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

### TC-AUTH-004 — Admin login success
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

### TC-AUTH-005 — Login fails with wrong password
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

### TC-AUTH-006 — Login fails for unknown email
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

### TC-AUTH-007 — Login fails for non-admin user
- **Priority:** P0
- **Method / Path:** `POST /api/v1/auth/login`
- **Auth:** none
- **Precondition:** A user exists with valid password but `role != 'admin'` (e.g. student)
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

### TC-AUTH-008 — Protected endpoint rejects missing token
- **Priority:** P0
- **Method / Path:** `GET /api/v1/assessments`
- **Auth:** none (intentionally omit Bearer)
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/assessments" \
    -H "X-Tenant-Scheme: $TENANT"
  ```
- **Expected status:** `401` (or auth middleware equivalent unauthorized)
- **Expected message:** (middleware-specific; assert non-empty `errors[0].message` or body indicates unauthorized)
- **Expected payload (validate):**
  - Response is an error envelope, not an assessments list
  - Must **not** contain top-level `assessments` array with data
