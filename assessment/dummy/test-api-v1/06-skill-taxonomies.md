# 06 — Skill Taxonomies

Requires `$TOKEN`. Seed data provides skill ids such as `SK-ENG-001` (`rails db:seed`).

---

### TC-TAX-001 — List all skill taxonomies
- **Priority:** P0
- **Method / Path:** `GET /api/v1/skill_taxonomies`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/skill_taxonomies" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `200`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - Top-level key: `skill_taxonomies` (array, ordered by `skill_id`)
  - Each item includes: `skill_id`, `skill_label`, `category`, `scope_include`, `scope_exclude`, `l1_anchor`…`l5_anchor`
  ```json
  {
    "skill_taxonomies": [
      {
        "skill_id": "SK-ENG-001",
        "skill_label": "React / Frontend Development Core",
        "category": "engineering",
        "scope_include": "...",
        "scope_exclude": "...",
        "l1_anchor": "...",
        "l2_anchor": "...",
        "l3_anchor": "...",
        "l4_anchor": "...",
        "l5_anchor": "..."
      }
    ]
  }
  ```
- **Save:** `$SKILL_ID` e.g. `SK-ENG-001`

---

### TC-TAX-002 — List skill taxonomies filtered by category
- **Priority:** P1
- **Method / Path:** `GET /api/v1/skill_taxonomies?category=engineering`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/skill_taxonomies?category=engineering" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `200`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - `skill_taxonomies` is array
  - Every item has `category` == `"engineering"`
  ```json
  {
    "skill_taxonomies": [
      { "skill_id": "SK-ENG-001", "category": "engineering" }
    ]
  }
  ```

---

### TC-TAX-003 — Get skill taxonomy by skill_id
- **Priority:** P0
- **Method / Path:** `GET /api/v1/skill_taxonomies/:skill_id`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/skill_taxonomies/$SKILL_ID" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `200`
- **Expected message:** `n/a`
- **Expected payload (validate):**
  - Top-level key: `skill` (not `skill_taxonomies`)
  - `skill.skill_id` == `$SKILL_ID`
  ```json
  {
    "skill": {
      "skill_id": "SK-ENG-001",
      "skill_label": "React / Frontend Development Core",
      "category": "engineering",
      "scope_include": "...",
      "scope_exclude": "...",
      "l1_anchor": "...",
      "l2_anchor": "...",
      "l3_anchor": "...",
      "l4_anchor": "...",
      "l5_anchor": "..."
    }
  }
  ```

---

### TC-TAX-004 — Get skill taxonomy not found
- **Priority:** P1
- **Method / Path:** `GET /api/v1/skill_taxonomies/:skill_id`
- **Auth:** Bearer JWT
- **curl:**
  ```bash
  curl -i "$BASE/api/v1/skill_taxonomies/SK-DOES-NOT-EXIST" \
    -H "Authorization: Bearer $TOKEN"
  ```
- **Expected status:** `404`
- **Expected message:** `Skill not found`
- **Expected payload (validate):**
  ```json
  {
    "errors": [
      { "status": 404, "message": "Skill not found" }
    ]
  }
  ```
