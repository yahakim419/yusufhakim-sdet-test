# 01 — Auth & Health (Analysis)

Evidence-based analysis for Auth & Health endpoints. **No test cases in this document.**

Sources: `api/` source, `documents/api-docs/`, prior suite intent in `assessment/test-api-v1/01-auth-and-health.md` (coverage context only). Live spot-checks against `http://localhost:3001` used only to confirm headers/messages where noted.

---

## 1. API Discovery

### Surface area

From `api/config/routes.rb` and `documents/api-docs/SUMMARY.md` / `openapi.yaml`, the Auth & Health public surface is:

| Method | Path | Implementation |
|--------|------|----------------|
| `GET` | `/health` | Inline Rack proc in `routes.rb` |
| `GET` | `/api/v1/health` | Inline Rack proc in `routes.rb` |
| `POST` | `/api/v1/speed_test` | Inline Rack proc in `routes.rb` |
| `POST` | `/api/v1/auth/login` | `Api::V1::AuthenticationController#authenticate` |

There are **no** HTTP routes for logout, refresh, register, password reset, or `/me`.

Protected-endpoint auth is not a separate route: controllers call `authorize_auth_token!` (e.g. `AssessmentsController`), which runs `AuthorizeApiRequest` on the `Authorization` header. The Auth suite’s missing-token smoke uses `GET /api/v1/assessments` as a representative protected resource.

### Middleware / stack

- `Rack::Attack` is mounted globally (`api/config/application.rb`). Login is throttled: **5 POSTs / minute / IP** to `/api/v1/auth/login` (`api/config/initializers/rack_attack.rb`). Over-limit → **429** with body `{ "error": "Too many requests. Please try again later." }` (not the standard `errors[]` envelope).
- `TenantResolverMiddleware` runs on every request. Resolution order: JWT `scheme` (decode without verification) → `X-Tenant-Scheme` → Referer host. If unresolved, request continues with no tenant.
- `AuthTokenMiddleware` exists but is **not** mounted. Comment in `application.rb`: controllers opt in via `authorize_auth_token!`.
- Health / speed_test Rack procs never hit `ApplicationController` (no `require_tenant!`, no JWT, no `ExceptionHandler`).
- Login skips `require_tenant!` (`AuthenticationController`).

### Error envelope (controller path)

From `Response#json_error` and `ExceptionHandler`:

```json
{
  "errors": [
    { "status": <http_code>, "message": "..." }
  ]
}
```

Optional `detail` when passed to `json_error`; optional `backtrace` in development for generic `StandardError`.

### Conventions (docs)

- Base URL: `http://localhost:3001`
- Public (no JWT): login, health, speed test (plus candidate invite-token endpoints outside this suite)
- Tenant: JWT `scheme` claim and/or `X-Tenant-Scheme`

---

## 2. Endpoint Inventory

| # | Method / Path | Auth | Tenant | Handler | Request | Success | Errors (code-backed) | Primary sources |
|---|---------------|------|--------|---------|---------|---------|----------------------|-----------------|
| 1 | `GET /health` | none | n/a (proc) | Rack proc | none | `200` `{ "status": "ok" }` | none defined | `routes.rb`, OpenAPI `/health` |
| 2 | `GET /api/v1/health` | none | n/a (proc) | Rack proc | none | `200` `{ "status": "ok" }` | none defined | `routes.rb`, OpenAPI `/api/v1/health` |
| 3 | `POST /api/v1/speed_test` | none | n/a (proc) | Rack proc | any body (optional) | `200` `{ "received_bytes": <int> }` | none defined | `routes.rb`, OpenAPI `/api/v1/speed_test` |
| 4 | `POST /api/v1/auth/login` | none (credentials in body) | optional `X-Tenant-Scheme` (JWT claim only; tenant not required) | `authentication#authenticate` | JSON `email`, `password` | `200` `{ "token", "user": { id, email, role } }` | `401` invalid/non-admin; `429` throttle | `authentication_controller.rb`, `user.rb`, `json_web_token.rb`, `rack_attack.rb`, OpenAPI |
| 5 | `GET /api/v1/assessments` (auth-gate smoke only) | Bearer JWT required | `require_tenant!` after middleware | `AssessmentsController` + `authorize_auth_token! :assessor` | none for gate | (success out of suite scope) | `401` missing/invalid token; `403` wrong role / tenant not found | `assessments_controller.rb`, `authorize_api_request.rb`, `exception_handler.rb`, `message.rb` |

---

## 3. API Contract Analysis

### `GET /health` and `GET /api/v1/health`

**Docs:** OpenAPI `HealthStatus` → `{ status: string }` example `"ok"`. Security: none.

**Code:** Both procs return `[200, {}, [{ status: 'ok' }.to_json]]`.

| Concern | Contract |
|---------|----------|
| Status | `200` |
| Body | `{ "status": "ok" }` |
| Headers | Proc sets **empty** header hash. Live check: body is JSON but **no `Content-Type: application/json`** (Rails may still add ETag / Cache-Control / etc.). Speed_test differs by setting `Content-Type`. |

### `POST /api/v1/speed_test`

**Docs:** Accepts any payload; returns `Content-Length` as `received_bytes`. Request body optional; content types include `application/octet-stream` and `application/json`.

**Code:**

```ruby
bytes = env['CONTENT_LENGTH'].to_i
[200, { 'Content-Type' => 'application/json' }, [{ received_bytes: bytes }.to_json]]
```

| Concern | Contract |
|---------|----------|
| Status | `200` |
| Body | `{ "received_bytes": <integer> }` equal to `CONTENT_LENGTH` (`.to_i`; missing → `0`) |
| Body handling | Request body is discarded; not parsed |
| Headers | Sets `Content-Type: application/json` |
| Live check | `{"ping":true}` → `received_bytes: 13` |

### `POST /api/v1/auth/login`

**Docs (OpenAPI):**
- Body required; properties `email` (string, format email), `password` (string, format password); both marked **required**
- Optional header `X-Tenant-Scheme`
- `200`: `{ token: string, user: User }` where `User` = `{ id, email, role }`
- `401`: `Unauthorized` → `ErrorEnvelope`

**Code:**
- Lookup: `User.find_by(email: params[:email].to_s.downcase)`
- Password: `user&.authenticate(params[:password])` (`has_secure_password`)
- Role gate: `user.role == 'admin'` else same 401 message
- Success: `json_response({ token:, user: { id:, email:, role: } })` — **inline hash, no serializer**
- Failure: `json_error('Invalid email or password', :unauthorized)` → HTTP 401 + envelope with `status: 401`
- Scheme embedded in JWT via `resolve_scheme` (header → `SELECT scheme FROM organizations LIMIT 1` → `'test-corp'`)
- JWT: `JsonWebToken.encode({ user_id:, role:, scheme: })` with `exp` default `ENV['TOKEN_EXPIRATION_TIME']` or **3 days**, HS256, `SECRET_KEY_BASE`

**Docs vs code gap:** OpenAPI marks email/password required, but the controller does **not** return 422 for missing/empty fields. Empty body `{}` yields the same **401** `"Invalid email or password"` (live check). Malformed JSON yields **500** `"Error occurred while parsing request parameters"` via generic `ExceptionHandler` (live check / Rails param parse).

### `GET /api/v1/assessments` (missing token — suite smoke)

**Code path:** `authorize_auth_token! :assessor` → `AuthorizeApiRequest#http_auth_header` raises `MissingToken` → `ExceptionHandler` renders **401** `{ errors: [{ status: 401, message: "Missing token" }] }`.

Live check without Bearer: `401` / `"Missing token"`. Response must not be an assessments list.

Wrong role after valid token → **403** `"Unauthorized request"` (not documented distinctly in OpenAPI `Unauthorized`, which conflates missing token and unauthorized role).

---

## 4. Validation Analysis

Per validation-matrix dimensions. Only conditions supported by `api/` + docs are listed.

### Health endpoints

| Field | Required | Type | Bounds / format | Notes |
|-------|----------|------|-----------------|-------|
| _(none)_ | — | — | — | No request fields; no query/body validation |

### Speed test

| Field | Required | Null | Type | Bounds | Notes |
|-------|----------|------|------|--------|-------|
| Body | optional | n/a | any | none | Discarded; not validated |
| `CONTENT_LENGTH` | implicit | — | integer via `.to_i` | none | Sole input to `received_bytes`; missing → `0` |

No type/format/enum/uniqueness/dependency validation on payload.

### Login — body

| Field | OpenAPI | Code required? | Null / empty | Type / format | Min/max length | Enum | Uniqueness | Depends on | Business |
|-------|---------|----------------|--------------|---------------|----------------|------|------------|------------|----------|
| `email` | required, format email | **Not enforced as 422** | `to_s.downcase`; blank → no user → 401 | treated as string | none in controller | — | DB unique on User (not checked at login beyond find) | password for authenticate | must match existing user |
| `password` | required | **Not enforced as 422** | blank/wrong fails `authenticate` → 401 | string via `has_secure_password` | none in controller | — | — | email lookup | bcrypt match |

Controller-layer: **no** separate required-field, type, format, or boundary validation. Invalid/missing credentials and non-admin all share one message/status.

Model validations (`presence`, email format, `role` inclusion) apply to **persistence**, not to the login action’s request validation.

### Login — header

| Field | Required | Notes |
|-------|----------|-------|
| `X-Tenant-Scheme` | optional | Used for JWT `scheme` claim; login skips `require_tenant!`. Invalid/missing header does not fail login. |

### Auth-gate smoke

| Field | Required | Notes |
|-------|----------|-------|
| `Authorization: Bearer <token>` | required for success | Missing → 401 `"Missing token"` |
| `X-Tenant-Scheme` | needed if JWT scheme / middleware cannot resolve org | Else `require_tenant!` → 403 `TenantNotFound` |

---

## 5. Business Logic Analysis

### Health / speed_test

- Pure liveness / byte-count utilities; no domain state, no auth, no tenant.
- Speed test measures declared content length, not actual read body bytes.

### Login — happy path

1. Find user by downcased email.
2. Authenticate password (`has_secure_password` / bcrypt).
3. Require `role == 'admin'` (`User::ROLES` = `%w[admin user]`; only admin may log in here).
4. Resolve scheme → encode JWT → return token + user subset.

### Login — failure / authz business rules

- Unknown email, wrong password, and **non-admin with valid password** all return the **same** 401 message: `"Invalid email or password"` (intentional non-disclosure of which check failed).
- No separate “forbidden role” status on login (unlike protected endpoints’ 403).

### Scheme / tenant business rules

- Login always issues a token even without a resolvable tenant (skipped `require_tenant!`).
- Scheme claim may later cause `TenantNotFound` (403) on protected endpoints if org cannot be identified.
- Fallback `SELECT scheme FROM organizations LIMIT 1` is **non-deterministic** if multiple organizations exist and header is omitted.

### JWT / protected resources

- Claims trusted; **no DB user re-fetch** on each request (`AuthorizeApiRequest` comment).
- Deleted/revoked users remain valid until token expiry.
- `:assessor` role group = `admin` | `assessor`. Login only issues `admin`. `assessor` is noted as a future/planned role in code comments; `User::ROLES` does not include `assessor`.
- Rate limit: 5 login attempts / minute / IP → 429 (different JSON shape).

### Preconditions for happy path

- Seeds create org `test-corp` but **do not create users** (`assessment/test-api-v1/README.md`). An admin user must exist out-of-band.

### Applicable business scenarios (checklist lens)

| Scenario | Applies? | Notes |
|----------|----------|-------|
| Valid business flow | Yes | Admin login; health/speed_test |
| Invalid business state | Limited | Non-admin login |
| Duplicate operation | No | Login is not a create-with-uniqueness |
| Non-existent resource | Partial | Unknown email → 401 (not 404) |
| Unauthorized resource | Yes (gate) | Missing token 401; wrong role 403 on protected |
| Completed / state transition | No | N/A |
| Dependency failure | Partial | Redis for Rack::Attack; DB for user/org lookup |

---

## 6. HTTP Status Code Analysis

Status codes derived from implementation (do not default invalid input to 400).

### Per-endpoint map

| Endpoint | Scenario | Status | Message / body | Evidence |
|----------|----------|--------|----------------|----------|
| Health (both) | Always | **200** | `{ "status": "ok" }` | `routes.rb` procs |
| Speed test | Always (proc) | **200** | `{ "received_bytes": N }` | `routes.rb` proc |
| Login | Admin + valid password | **200** | `{ token, user }` | `json_response` default `:ok` |
| Login | Unknown email / wrong password / non-admin | **401** | `"Invalid email or password"` | `json_error(..., :unauthorized)` |
| Login | Empty `{}` body | **401** | same message | live + `find_by`/`authenticate` path |
| Login | Malformed JSON body | **500** | `"Error occurred while parsing request parameters"` | Rails parse + `ExceptionHandler` generic |
| Login | >5 POST/min/IP | **429** | `{ "error": "Too many requests..." }` (not `errors[]`) | `rack_attack.rb` |
| Assessments (gate) | Missing Bearer | **401** | `"Missing token"` | `MissingToken` / `Message.missing_token` |
| Assessments (gate) | Invalid/expired JWT | **401** | invalid-token message from JWT decode | `InvalidToken` |
| Assessments (gate) | Valid JWT, role not in assessor group | **403** | `"Unauthorized request"` | `ExceptionHandler::Unauthorized` |
| Assessments (gate) | Tenant unresolved | **403** | `"Tenant not found. Ensure the JWT scheme claim is valid."` | `require_tenant!` |

### Statuses not used by Auth/Health handlers

- **201 / 202 / 204** — not returned by these endpoints
- **400** — not explicitly returned by login/health/speed_test
- **404** — unknown email is **401**, not 404
- **409** — n/a
- **422** — OpenAPI “required” fields are **not** enforced as 422 on login; controller does not use validation that would map to 422 for this action

---

## Gaps & Risks

### Unknown behavior

- Exact client/proxy behavior when health responses lack `Content-Type` (some clients still parse JSON; strict clients may not).
- Chunked / streaming uploads to `speed_test` without `CONTENT_LENGTH` → `received_bytes: 0` regardless of body size.
- Behavior when `REDIS_URL` is unavailable for Rack::Attack cache (store configuration assumes Redis).
- Whether `params[:password]` as non-string (e.g. JSON number/object) raises or fails authenticate — not exhaustively exercised in source-only review.
- Multi-org DB: which scheme `LIMIT 1` returns is DB-order dependent.

### Unsupported assumptions

- Assuming OpenAPI `required: [email, password]` implies **422** — **unsupported**; code returns **401** for missing/empty credentials.
- Assuming OpenAPI `Unauthorized` always means **401** — **unsupported** for protected endpoints; wrong role / tenant → **403**.
- Assuming `rails db:seed` yields a login-ready admin — **unsupported**; users are not seeded.
- Assuming `AuthTokenMiddleware` participates in request auth — **unsupported**; it is not mounted.
- Assuming `User` role `assessor` or `student` can be created via model validations — **unsupported**; `User::ROLES` is only `admin` | `user`.
- Assuming speed_test `received_bytes` equals UTF-8 body byte length after proxy mutation — only **`CONTENT_LENGTH`** is authoritative.

### Missing information

- Canonical procedure to create an admin user for local/CI test runs (console snippet, fixture, or script).
- Local value of `TOKEN_EXPIRATION_TIME` and whether expiry tests are expected in this suite.
- Whether rate-limit 429 is in-scope for Auth suite coverage and how to reset Redis throttle state between runs.
- Intended Content-Type expectation for health checks (docs imply `application/json`; code omits header).
- Whether login without `X-Tenant-Scheme` is an official supported path when multiple orgs exist.

### Potential coverage risks

- **v1 TC-AUTH-008** asserts assessments auth-gate, not login controller behavior — easy to conflate login 401 messages with `"Missing token"`.
- Login failure modes (bad password, unknown email, non-admin, empty fields) share **identical** status/message — tests cannot distinguish root cause from response alone; need controlled fixtures.
- **Rack::Attack 429** and non-envelope `{ "error": ... }` are easy to miss; rapid negative login cases in CI can flake or mask real assertions.
- Speed test coverage that only sends JSON may miss `CONTENT_LENGTH` / empty-body / missing-header cases.
- Health `Content-Type` omission vs OpenAPI `application/json` content — assertion risk if tests require header.
- Post-login tenant mismatch (token scheme vs missing org) surfaces on **later** suites as 403, not at login — Auth suite may under-cover scheme fallback.
- JWT trusts claims with no DB check — revocation/deleted-user scenarios are out of band and easy to omit.
- Malformed JSON → **500** is reproducible but may be classified incorrectly as client 4xx if assumed from OpenAPI alone.
