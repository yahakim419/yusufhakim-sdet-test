# Web → API assessment skills payload contract

Reference contract for the assessment builder seam. **Not executed in `web/`** (product freeze). Use as Spec/AC link for DoR and as the expected client payload shape the external API e2e already exercises via curl.

## Taxonomy pick → nested create/update

When the assessor picks a B7 taxonomy row, the PUT/POST nested attribute must retain identity:

```json
{
  "skill_id": "SK-ENG-001",
  "skill_label": "…",
  "is_custom": false,
  "scope_include": "…",
  "scope_exclude": "…",
  "l1_anchor": "…",
  "l2_anchor": "…",
  "l3_anchor": "…",
  "l4_anchor": "…",
  "l5_anchor": "…",
  "expected_level": 3,
  "display_order": 1
}
```

**Defect class (audit #2):** dropping `skill_id` or `scope_exclude` at pick time stores a false taxonomy claim.

## Edit remove → nested `_destroy`

Rails `accepts_nested_attributes_for … allow_destroy: true` deletes only when the client sends:

```json
{
  "id": 123,
  "_destroy": true
}
```

Omitting a skill from the attributes array does **not** destroy it.

**Defect class (audit #1):** UI `remove(index)` + PUT of remaining skills only → API keeps deleted skills.

## Fixture (expected destroy payload)

See [`../fixtures/assessment_skills_destroy.json`](../fixtures/assessment_skills_destroy.json).

## How this is checked without touching `web/`

- API continuity (add/destroy with correct payloads): [`e2e_business_flow.sh`](e2e_business_flow.sh) TC-E2E-005…008.
- Web builder correctness: **open P0** in [`../01-audit.md`](../01-audit.md) until a product fix pass; release stays **blocked**.
