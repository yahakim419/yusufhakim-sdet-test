# Branch protection for merge-blocking quality checks

Required status check names (after each has run at least once on the default branch):

| Check | Workflow | Blocks |
|-------|----------|--------|
| `lint` | [lint.yml](workflows/lint.yml) | Style / type |
| `quality` | [quality.yml](workflows/quality.yml) | DoR + external e2e |

## GitHub UI

1. Open **Settings → Rules → Rulesets** (or **Branches → Branch protection rules**).
2. Create a rule targeting `main`.
3. Enable **Require status checks to pass before merging**.
4. Add required checks: `lint`, `quality`.
5. Enable **Require branches to be up to date before merging**.
6. Do **not** allow bypass for typical submitters (admins optional).

## GitHub CLI

```bash
gh api repos/yahakim419/yusufhakim-sdet-test/branches/main/protection \
  --method PUT \
  --input - <<'EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["lint", "quality"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
```

## Local commands

| Check | Command |
|-------|---------|
| API lint | `cd api && bundle exec rubocop` |
| External e2e | `BASE_URL=… E2E_EMAIL=… E2E_PASSWORD=… ./assessment/scripts/e2e_business_flow.sh` |
| External e2e (CI helper) | `.github/scripts/run-external-e2e.sh` |
| Web lint | `cd web && npm run lint && npm run typecheck` |
| DoR script | `.github/scripts/check-dor.sh /path/to/pr-body.md` |
