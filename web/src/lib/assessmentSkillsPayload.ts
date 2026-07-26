import type { AssessmentSkill, SkillTaxonomy } from "@/types";

/** Map a B7 taxonomy row into nested assessment_skills_attributes fields. */
export function taxonomyToAssessmentSkill(
  taxonomy: SkillTaxonomy,
  overrides: Partial<AssessmentSkill> = {}
): Partial<AssessmentSkill> {
  return {
    skill_id: taxonomy.skill_id,
    skill_label: taxonomy.skill_label,
    is_custom: false,
    expected_level: 3,
    scope_include: taxonomy.scope_include,
    scope_exclude: taxonomy.scope_exclude,
    l1_anchor: taxonomy.l1_anchor,
    l2_anchor: taxonomy.l2_anchor,
    l3_anchor: taxonomy.l3_anchor,
    l4_anchor: taxonomy.l4_anchor,
    l5_anchor: taxonomy.l5_anchor,
    ...overrides,
  };
}

/**
 * Build nested attributes for PUT update.
 * Rails nested attrs do not delete omitted records — removed persisted ids must
 * be sent as `{ id, _destroy: true }`.
 */
export function buildNestedSkillsAttributes(
  skills: Partial<AssessmentSkill>[],
  previouslyPersistedIds: number[]
): Array<Partial<AssessmentSkill> & { display_order: number }> {
  const keptIds = new Set(
    skills
      .map((s) => s.id)
      .filter((id): id is number => typeof id === "number")
  );

  const attrs: Array<Partial<AssessmentSkill> & { display_order: number }> =
    skills.map((s, i) => ({ ...s, display_order: i }));

  for (const id of previouslyPersistedIds) {
    if (!keptIds.has(id)) {
      attrs.push({ id, _destroy: true, display_order: 0 });
    }
  }

  return attrs;
}
