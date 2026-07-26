# Branch protection for merge-blocking lint

The `lint` job in [`.github/workflows/lint.yml`](workflows/lint.yml) is the required status check name.

GitHub only lists a check after it has run at least once on the default branch. After merging this workflow (or pushing it to `main`), apply protection:

## GitHub UI

1. Open **Settings → Rules → Rulesets** (or **Branches → Branch protection rules**).
2. Create a rule targeting `main`.
3. Enable **Require status checks to pass before merging**.
4. Add required check: `lint`.
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
    "contexts": ["lint"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
```

## Local lint commands

| App | Command |
|-----|---------|
| API | `cd api && bundle exec rubocop` |
| Web | `cd web && npm run lint && npm run typecheck` |
