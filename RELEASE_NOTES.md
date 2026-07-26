# Release notes — v1.0.0

## Claims

This version claims a **workflow quality net** for the assessment builder critical path — not client-ready skill-builder product trustworthiness.

Included:

- Ranked audit of assessments+skills risks (`assessment/01-audit.md`) with open P0/P1 product seams
- External curl e2e for TC-E2E-001…008 (`assessment/scripts/e2e_business_flow.sh`)
- Definition-of-Ready PR gate (`.github/scripts/check-dor.sh` + `quality.yml`)
- Web→API payload contract documented outside `web/` (`assessment/scripts/web_payload_contract.md`)
- Release-gated CI on `v*` tags that surfaces **BLOCKED** while open P0/P1s remain

## Not claimed

- Web edit remove / taxonomy `skill_id` persistence fixes (product freeze; audit P0s **open**)
- Create `201` skills key parity with show/update
- `system_prompt_generated` meaning true generation success
- Portfolio / fit-gap / interview session correctness
- Multi-tenant fail-closed hardening
- Signup / login UI completeness

## Status

**BLOCKED** for client delivery of the assessment + skills builder. See `assessment/03-release-decision.md`.
