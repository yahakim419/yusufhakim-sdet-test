import { describe, expect, it } from "vitest";
import {
  buildNestedSkillsAttributes,
  taxonomyToAssessmentSkill,
} from "./assessmentSkillsPayload";
import type { SkillTaxonomy } from "@/types";

const taxonomy: SkillTaxonomy = {
  skill_id: "SK-ENG-001",
  skill_label: "React / Frontend Development Core",
  category: "engineering",
  scope_include: "Component design",
  scope_exclude: "Backend APIs",
  l1_anchor: "L1",
  l2_anchor: "L2",
  l3_anchor: "L3",
  l4_anchor: "L4",
  l5_anchor: "L5",
};

describe("taxonomyToAssessmentSkill", () => {
  it("preserves taxonomy skill_id and scope_exclude (TC-E2E-005 continuity)", () => {
    const skill = taxonomyToAssessmentSkill(taxonomy);
    expect(skill.skill_id).toBe("SK-ENG-001");
    expect(skill.scope_exclude).toBe("Backend APIs");
    expect(skill.is_custom).toBe(false);
    expect(skill.skill_label).toBe(taxonomy.skill_label);
  });
});

describe("buildNestedSkillsAttributes", () => {
  it("emits _destroy for removed persisted skills (TC-E2E-007/008)", () => {
    const remaining = [
      {
        id: 11,
        skill_label: "E2E Custom Negotiation",
        is_custom: true,
        expected_level: 2,
        display_order: 0,
      },
    ];
    const attrs = buildNestedSkillsAttributes(remaining, [10, 11]);
    const destroy = attrs.find((a) => a.id === 10 && a._destroy === true);
    expect(destroy).toBeDefined();
    expect(attrs.find((a) => a.id === 11 && !a._destroy)).toBeDefined();
  });

  it("does not destroy skills still present", () => {
    const remaining = [
      { id: 10, skill_id: "SK-ENG-001", skill_label: "React", is_custom: false, expected_level: 3, display_order: 0 },
      { id: 11, skill_label: "Custom", is_custom: true, expected_level: 2, display_order: 1 },
    ];
    const attrs = buildNestedSkillsAttributes(remaining, [10, 11]);
    expect(attrs.every((a) => !a._destroy)).toBe(true);
  });
});
