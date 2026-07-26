#!/usr/bin/env bash
# External e2e: TC-E2E-001 → TC-E2E-008 against a running API.
# Does not modify api/ or web/. Asserts persisted re-read, not status alone.
#
# Required env:
#   BASE_URL     (default http://localhost:3001)
#   E2E_EMAIL    admin login email
#   E2E_PASSWORD admin login password
#
# Optional:
#   X_TENANT_SCHEME (default test-corp)
#
# Prerequisites: jq, curl; API up with seeded taxonomies + admin user.
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:3001}"
BASE="${BASE_URL%/}"
E2E_EMAIL="${E2E_EMAIL:-}"
E2E_PASSWORD="${E2E_PASSWORD:-}"
X_TENANT_SCHEME="${X_TENANT_SCHEME:-test-corp}"
ASSESSMENT_NAME="E2E Business Flow Assessment"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

need() {
  command -v "$1" >/dev/null 2>&1 || fail "missing dependency: $1"
}

need curl
need jq

if [[ -z "$E2E_EMAIL" || -z "$E2E_PASSWORD" ]]; then
  fail "Set E2E_EMAIL and E2E_PASSWORD (admin credentials). Do not edit api/ seeds for this suite."
fi

auth_hdr=(-H "Authorization: Bearer ${TOKEN:-}" -H "X-Tenant-Scheme: ${X_TENANT_SCHEME}" -H "Content-Type: application/json" -H "Accept: application/json")

http_json() {
  # usage: http_json METHOD PATH [data]
  local method="$1" path="$2" data="${3:-}"
  local tmp code body
  tmp="$(mktemp)"
  if [[ -n "$data" ]]; then
    code="$(curl -sS -o "$tmp" -w "%{http_code}" -X "$method" "${BASE}${path}" "${auth_hdr[@]}" -d "$data")"
  else
    code="$(curl -sS -o "$tmp" -w "%{http_code}" -X "$method" "${BASE}${path}" "${auth_hdr[@]}")"
  fi
  body="$(cat "$tmp")"
  rm -f "$tmp"
  echo "$code"
  echo "$body"
}

expect_status() {
  local got="$1" want="$2" step="$3"
  [[ "$got" == "$want" ]] || fail "$step: expected HTTP $want, got $got"
}

echo "== External e2e business flow against ${BASE} =="

# --- Login (setup only) ---
login_payload="$(jq -n --arg e "$E2E_EMAIL" --arg p "$E2E_PASSWORD" '{email:$e,password:$p}')"
login_tmp="$(mktemp)"
login_code="$(curl -sS -o "$login_tmp" -w "%{http_code}" -X POST "${BASE}/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -H "X-Tenant-Scheme: ${X_TENANT_SCHEME}" \
  -d "$login_payload")"
login_body="$(cat "$login_tmp")"
rm -f "$login_tmp"

[[ "$login_code" == "200" ]] || fail "login: expected 200, got ${login_code}. Body: ${login_body}"
TOKEN="$(echo "$login_body" | jq -r '.token // empty')"
[[ -n "$TOKEN" && "$TOKEN" != "null" ]] || fail "login: missing token in response"
auth_hdr=(-H "Authorization: Bearer ${TOKEN}" -H "X-Tenant-Scheme: ${X_TENANT_SCHEME}" -H "Content-Type: application/json" -H "Accept: application/json")
echo "OK: login"

# --- TC-E2E-001 Create ---
create_payload="$(jq -n --arg n "$ASSESSMENT_NAME" '{assessment:{name:$n,time_limit_min:30,language:"en"}}')"
create_out="$(http_json POST /api/v1/assessments "$create_payload")"
create_code="$(echo "$create_out" | head -n1)"
create_body="$(echo "$create_out" | tail -n +2)"
expect_status "$create_code" "201" "TC-E2E-001"
ASSESSMENT_ID="$(echo "$create_body" | jq -r '.assessment.id')"
name_got="$(echo "$create_body" | jq -r '.assessment.name')"
tl_got="$(echo "$create_body" | jq -r '.assessment.time_limit_min')"
spg="$(echo "$create_body" | jq -r '.system_prompt_generated')"
[[ "$ASSESSMENT_ID" =~ ^[0-9]+$ ]] || fail "TC-E2E-001: assessment.id missing"
[[ "$name_got" == "$ASSESSMENT_NAME" ]] || fail "TC-E2E-001: name mismatch"
[[ "$tl_got" == "30" ]] || fail "TC-E2E-001: time_limit_min mismatch"
[[ "$spg" == "true" ]] || fail "TC-E2E-001: system_prompt_generated expected true"
echo "OK: TC-E2E-001 create id=${ASSESSMENT_ID}"

# --- TC-E2E-002 List ---
list_out="$(http_json GET "/api/v1/assessments?page=1&per_page=20")"
list_code="$(echo "$list_out" | head -n1)"
list_body="$(echo "$list_out" | tail -n +2)"
expect_status "$list_code" "200" "TC-E2E-002"
match_count="$(echo "$list_body" | jq --argjson id "$ASSESSMENT_ID" --arg n "$ASSESSMENT_NAME" \
  '[.assessments[] | select(.id == $id and .name == $n)] | length')"
[[ "$match_count" -ge 1 ]] || fail "TC-E2E-002: list missing id+name pair for ${ASSESSMENT_ID}"
echo "OK: TC-E2E-002 list"

# --- TC-E2E-003 Taxonomies ---
tax_out="$(http_json GET /api/v1/skill_taxonomies)"
tax_code="$(echo "$tax_out" | head -n1)"
tax_body="$(echo "$tax_out" | tail -n +2)"
expect_status "$tax_code" "200" "TC-E2E-003"
tax_len="$(echo "$tax_body" | jq '.skill_taxonomies | length')"
[[ "$tax_len" -ge 1 ]] || fail "TC-E2E-003: skill_taxonomies empty (seed required)"
TAX_SKILL_ID="$(echo "$tax_body" | jq -r '.skill_taxonomies[0].skill_id')"
TAX_SKILL_LABEL="$(echo "$tax_body" | jq -r '.skill_taxonomies[0].skill_label')"
TAX_SCOPE_INCLUDE="$(echo "$tax_body" | jq -r '.skill_taxonomies[0].scope_include // ""')"
TAX_SCOPE_EXCLUDE="$(echo "$tax_body" | jq -r '.skill_taxonomies[0].scope_exclude // ""')"
TAX_L1="$(echo "$tax_body" | jq -r '.skill_taxonomies[0].l1_anchor // ""')"
TAX_L2="$(echo "$tax_body" | jq -r '.skill_taxonomies[0].l2_anchor // ""')"
TAX_L3="$(echo "$tax_body" | jq -r '.skill_taxonomies[0].l3_anchor // ""')"
TAX_L4="$(echo "$tax_body" | jq -r '.skill_taxonomies[0].l4_anchor // ""')"
TAX_L5="$(echo "$tax_body" | jq -r '.skill_taxonomies[0].l5_anchor // ""')"
[[ -n "$TAX_SKILL_ID" && "$TAX_SKILL_ID" != "null" ]] || fail "TC-E2E-003: skill_id missing on first taxonomy"
echo "OK: TC-E2E-003 taxonomies (${TAX_SKILL_ID})"

# --- TC-E2E-004 Show baseline ---
show_out="$(http_json GET "/api/v1/assessments/${ASSESSMENT_ID}")"
show_code="$(echo "$show_out" | head -n1)"
show_body="$(echo "$show_out" | tail -n +2)"
expect_status "$show_code" "200" "TC-E2E-004"
[[ "$(echo "$show_body" | jq -r '.assessment.id')" == "$ASSESSMENT_ID" ]] || fail "TC-E2E-004: id mismatch"
[[ "$(echo "$show_body" | jq -r '.assessment.name')" == "$ASSESSMENT_NAME" ]] || fail "TC-E2E-004: name mismatch"
[[ "$(echo "$show_body" | jq -r '.assessment.time_limit_min')" == "30" ]] || fail "TC-E2E-004: time_limit_min mismatch"
echo "$show_body" | jq -e '.assessment.skills | type == "array"' >/dev/null || fail "TC-E2E-004: skills not array"
echo "OK: TC-E2E-004 show"

# --- TC-E2E-005 Add taxonomy skill ---
put_tax="$(jq -n \
  --arg n "$ASSESSMENT_NAME" \
  --arg sid "$TAX_SKILL_ID" \
  --arg sl "$TAX_SKILL_LABEL" \
  --arg si "$TAX_SCOPE_INCLUDE" \
  --arg se "$TAX_SCOPE_EXCLUDE" \
  --arg l1 "$TAX_L1" --arg l2 "$TAX_L2" --arg l3 "$TAX_L3" --arg l4 "$TAX_L4" --arg l5 "$TAX_L5" \
  '{assessment:{name:$n,time_limit_min:30,language:"en",assessment_skills_attributes:[{
    skill_id:$sid,skill_label:$sl,is_custom:false,scope_include:$si,scope_exclude:$se,
    l1_anchor:$l1,l2_anchor:$l2,l3_anchor:$l3,l4_anchor:$l4,l5_anchor:$l5,
    expected_level:3,display_order:1
  }]}}')"
put1_out="$(http_json PUT "/api/v1/assessments/${ASSESSMENT_ID}" "$put_tax")"
put1_code="$(echo "$put1_out" | head -n1)"
expect_status "$put1_code" "200" "TC-E2E-005 PUT"
get5_out="$(http_json GET "/api/v1/assessments/${ASSESSMENT_ID}")"
get5_code="$(echo "$get5_out" | head -n1)"
get5_body="$(echo "$get5_out" | tail -n +2)"
expect_status "$get5_code" "200" "TC-E2E-005 GET"
TAX_ASSESSMENT_SKILL_ID="$(echo "$get5_body" | jq -r --arg sid "$TAX_SKILL_ID" \
  '.assessment.skills[] | select(.skill_id == $sid and .is_custom == false) | .id' | head -n1)"
[[ "$TAX_ASSESSMENT_SKILL_ID" =~ ^[0-9]+$ ]] || fail "TC-E2E-005: taxonomy skill not persisted with skill_id=${TAX_SKILL_ID}"
label_ok="$(echo "$get5_body" | jq -r --argjson id "$TAX_ASSESSMENT_SKILL_ID" --arg sl "$TAX_SKILL_LABEL" \
  '.assessment.skills[] | select(.id == $id) | .skill_label')"
[[ "$label_ok" == "$TAX_SKILL_LABEL" ]] || fail "TC-E2E-005: skill_label mismatch on re-read"
echo "OK: TC-E2E-005 taxonomy skill id=${TAX_ASSESSMENT_SKILL_ID}"

# --- TC-E2E-006 Add custom skill (keep taxonomy) ---
put_custom="$(jq -n \
  --arg n "$ASSESSMENT_NAME" \
  '{assessment:{name:$n,time_limit_min:30,language:"en",assessment_skills_attributes:[{
    skill_id:null,skill_label:"E2E Custom Negotiation",is_custom:true,
    scope_include:"Stakeholder alignment",scope_exclude:"Legal drafting",
    l1_anchor:"L1 custom",l2_anchor:"L2 custom",l3_anchor:"L3 custom",
    l4_anchor:"L4 custom",l5_anchor:"L5 custom",expected_level:2,display_order:2
  }]}}')"
put2_out="$(http_json PUT "/api/v1/assessments/${ASSESSMENT_ID}" "$put_custom")"
put2_code="$(echo "$put2_out" | head -n1)"
expect_status "$put2_code" "200" "TC-E2E-006 PUT"
get6_out="$(http_json GET "/api/v1/assessments/${ASSESSMENT_ID}")"
get6_code="$(echo "$get6_out" | head -n1)"
get6_body="$(echo "$get6_out" | tail -n +2)"
expect_status "$get6_code" "200" "TC-E2E-006 GET"
CUSTOM_ASSESSMENT_SKILL_ID="$(echo "$get6_body" | jq -r \
  '.assessment.skills[] | select(.skill_label == "E2E Custom Negotiation" and .is_custom == true) | .id' | head -n1)"
[[ "$CUSTOM_ASSESSMENT_SKILL_ID" =~ ^[0-9]+$ ]] || fail "TC-E2E-006: custom skill not persisted"
tax_still="$(echo "$get6_body" | jq --argjson id "$TAX_ASSESSMENT_SKILL_ID" \
  '[.assessment.skills[] | select(.id == $id)] | length')"
[[ "$tax_still" -eq 1 ]] || fail "TC-E2E-006: taxonomy skill dropped after custom add"
echo "OK: TC-E2E-006 mixed skills (custom id=${CUSTOM_ASSESSMENT_SKILL_ID})"

# --- TC-E2E-007 Destroy taxonomy only ---
put_destroy_tax="$(jq -n \
  --arg n "$ASSESSMENT_NAME" \
  --argjson tid "$TAX_ASSESSMENT_SKILL_ID" \
  '{assessment:{name:$n,time_limit_min:30,language:"en",assessment_skills_attributes:[{id:$tid,_destroy:true}]}}')"
put7_out="$(http_json PUT "/api/v1/assessments/${ASSESSMENT_ID}" "$put_destroy_tax")"
put7_code="$(echo "$put7_out" | head -n1)"
expect_status "$put7_code" "200" "TC-E2E-007 PUT"
get7_out="$(http_json GET "/api/v1/assessments/${ASSESSMENT_ID}")"
get7_code="$(echo "$get7_out" | head -n1)"
get7_body="$(echo "$get7_out" | tail -n +2)"
expect_status "$get7_code" "200" "TC-E2E-007 GET"
tax_gone="$(echo "$get7_body" | jq --argjson id "$TAX_ASSESSMENT_SKILL_ID" \
  '[.assessment.skills[] | select(.id == $id)] | length')"
[[ "$tax_gone" -eq 0 ]] || fail "TC-E2E-007: taxonomy skill still present after _destroy"
custom_kept="$(echo "$get7_body" | jq --argjson id "$CUSTOM_ASSESSMENT_SKILL_ID" \
  '[.assessment.skills[] | select(.id == $id and .is_custom == true)] | length')"
[[ "$custom_kept" -eq 1 ]] || fail "TC-E2E-007: custom skill missing after taxonomy destroy"
echo "OK: TC-E2E-007 selective _destroy taxonomy"

# --- TC-E2E-008 Destroy custom; assessment remains ---
put_destroy_custom="$(jq -n \
  --arg n "$ASSESSMENT_NAME" \
  --argjson cid "$CUSTOM_ASSESSMENT_SKILL_ID" \
  '{assessment:{name:$n,time_limit_min:30,language:"en",assessment_skills_attributes:[{id:$cid,_destroy:true}]}}')"
put8_out="$(http_json PUT "/api/v1/assessments/${ASSESSMENT_ID}" "$put_destroy_custom")"
put8_code="$(echo "$put8_out" | head -n1)"
expect_status "$put8_code" "200" "TC-E2E-008 PUT"
get8_out="$(http_json GET "/api/v1/assessments/${ASSESSMENT_ID}")"
get8_code="$(echo "$get8_out" | head -n1)"
get8_body="$(echo "$get8_out" | tail -n +2)"
expect_status "$get8_code" "200" "TC-E2E-008 GET"
[[ "$(echo "$get8_body" | jq -r '.assessment.id')" == "$ASSESSMENT_ID" ]] || fail "TC-E2E-008: assessment row missing"
custom_gone="$(echo "$get8_body" | jq --argjson id "$CUSTOM_ASSESSMENT_SKILL_ID" \
  '[.assessment.skills[] | select(.id == $id)] | length')"
[[ "$custom_gone" -eq 0 ]] || fail "TC-E2E-008: custom skill still present"
nego="$(echo "$get8_body" | jq '[.assessment.skills[] | select(.skill_label == "E2E Custom Negotiation")] | length')"
[[ "$nego" -eq 0 ]] || fail "TC-E2E-008: custom label still present"
skills_len="$(echo "$get8_body" | jq '.assessment.skills | length')"
[[ "$skills_len" -eq 0 ]] || fail "TC-E2E-008: expected empty skills, got ${skills_len}"
echo "OK: TC-E2E-008 destroy custom; assessment remains"

echo ""
echo "PASS: TC-E2E-001 → TC-E2E-008"
