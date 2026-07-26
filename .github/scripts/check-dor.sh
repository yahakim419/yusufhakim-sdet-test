#!/usr/bin/env bash
# Fails if a pull request body is missing Definition-of-Ready sections.
set -euo pipefail

BODY_FILE="${1:-}"
if [[ -z "$BODY_FILE" || ! -f "$BODY_FILE" ]]; then
  echo "Usage: check-dor.sh <pr-body-file>"
  exit 2
fi

body="$(cat "$BODY_FILE")"

missing=0

require_section() {
  local label="$1"
  local pattern="$2"
  if ! echo "$body" | grep -Eqi "$pattern"; then
    echo "FAIL: missing DoR section: $label"
    missing=1
  else
    echo "OK: found $label"
  fi
}

require_section "Spec / PRD" "Spec[[:space:]]*/[[:space:]]*PRD"
require_section "Acceptance criteria / test scenarios" "Acceptance criteria|test scenarios"
require_section "Solution / design plan" "Solution[[:space:]]*/[[:space:]]*design plan|Design plan"

# Require at least one non-placeholder link-like token under DoR (http, assessment/, or path)
if ! echo "$body" | grep -Eqi '(https?://|assessment/|[A-Za-z0-9._/-]+\.(md|txt))'; then
  echo "FAIL: DoR must include at least one real link or path (http(s), assessment/, or *.md)"
  missing=1
fi

# Reject empty template markers left as-is
if echo "$body" | grep -Eq '<!-- e\.g\.'; then
  echo "FAIL: replace template placeholders (<!-- e.g. ... -->) with real links"
  missing=1
fi

if [[ "$missing" -ne 0 ]]; then
  echo ""
  echo "Definition of Ready not met. Fill Spec/PRD, Acceptance criteria, and Design plan with real links."
  exit 1
fi

echo "Definition of Ready checks passed."
