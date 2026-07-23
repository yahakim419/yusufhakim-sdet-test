# API Test Cases

Manual curl-based test cases for the Rails API (`http://localhost:3001`).

Derived from [`documents/api-docs/SUMMARY.md`](../../documents/api-docs/SUMMARY.md) and controllers under `api/app/controllers/api/v1/`.

## Suites

| File | Coverage |
|------|----------|
| [01-auth-and-health.md](01-auth-and-health.md) | Health, login |
| [02-assessments.md](02-assessments.md) | Assessment CRUD |
| [03-sessions.md](03-sessions.md) | Sessions + candidate public flows |
| [04-portfolios.md](04-portfolios.md) | Portfolio, fit/gap, export, overrides |
| [05-vacancies.md](05-vacancies.md) | Vacancy CRUD |
| [06-skill-taxonomies.md](06-skill-taxonomies.md) | Skill taxonomy read APIs |

## Prerequisites

1. API running on port **3001** (see `api/README.md`).
2. DB seeded (`rails db:seed`) so tenant scheme `test-corp` and skill taxonomies exist.
3. An **admin** user in the tenant (login only accepts `role == 'admin'`). Seeds do not create users — create one or use an existing account.

## Environment (PowerShell)

```powershell
$BASE   = "http://localhost:3001"
$TENANT = "test-corp"
$EMAIL  = "admin@example.com"   # replace with your admin email
$PASS   = "your-password"       # replace with your admin password
```

### Obtain JWT

```powershell
$login = curl.exe -s -X POST "$BASE/api/v1/auth/login" `
  -H "Content-Type: application/json" `
  -H "X-Tenant-Scheme: $TENANT" `
  -d "{`"email`":`"$EMAIL`",`"password`":`"$PASS`"}" | ConvertFrom-Json
$TOKEN = $login.token
```

Or bash:

```bash
export BASE=http://localhost:3001
export TENANT=test-corp
export TOKEN=$(curl -s -X POST "$BASE/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -H "X-Tenant-Scheme: $TENANT" \
  -d '{"email":"admin@example.com","password":"your-password"}' | jq -r .token)
```

### Common headers

| Header | When |
|--------|------|
| `Authorization: Bearer $TOKEN` | Assessor/admin endpoints |
| `X-Tenant-Scheme: test-corp` | Login / when JWT has no scheme |
| `Content-Type: application/json` | JSON bodies |

## How to validate each case

For every TC, check:

1. **HTTP status** matches **Expected status**
2. **Message** matches **Expected message** when present (`errors[0].message` for errors, or top-level `message`)
3. **Payload** contains the keys/types listed under **Expected payload (validate)**

Error envelope shape:

```json
{
  "errors": [
    { "status": 401, "message": "..." }
  ]
}
```

## Suggested execution order

1. `01-auth-and-health` → capture `$TOKEN`
2. `02-assessments` → capture `$ASSESSMENT_ID`
3. `03-sessions` → capture `$SESSION_ID`, `$INVITE_TOKEN`
4. `05-vacancies` → capture `$VACANCY_ID` (needed for fit/gap)
5. `06-skill-taxonomies`
6. `04-portfolios` (needs ended session + generated portfolio; may require waiting on Sidekiq)

## Placeholders used in curls

| Variable | Meaning |
|----------|---------|
| `$BASE` | `http://localhost:3001` |
| `$TOKEN` | JWT from login |
| `$TENANT` | `test-corp` |
| `$ASSESSMENT_ID` | From create assessment |
| `$SESSION_ID` | From create session |
| `$INVITE_TOKEN` | From session `invite_token` |
| `$PORTFOLIO_ID` | From portfolio response |
| `$PORTFOLIO_SKILL_ID` | From portfolio `skills[].id` |
| `$VACANCY_ID` | From create vacancy |
| `$SKILL_ID` | e.g. `SK-ENG-001` from seeds |
