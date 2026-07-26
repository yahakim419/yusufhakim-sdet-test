# frozen_string_literal: true

require 'rails_helper'

# Automates assessment/tc-api/e2e-business-flow.md TC-E2E-001 → TC-E2E-008.
# Asserts persisted continuity (id/name/skills), not HTTP status alone.
RSpec.describe 'E2E business flow — assessments + skills', type: :request do
  let(:headers) { auth_headers }
  let(:assessment_name) { 'E2E Business Flow Assessment' }

  before do
    ensure_test_org!
    create_admin_user!
    seed_taxonomy_skill!
  end

  # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations -- intentional single continuity scenario TC-E2E-001..008
  it 'create → list → taxonomies → show → add/remove skills with re-read continuity' do
    # TC-E2E-001 — Create
    post '/api/v1/assessments',
         params: {
           assessment: {
             name: assessment_name,
             time_limit_min: 30,
             language: 'en'
           }
         }.to_json,
         headers: headers

    expect(response).to have_http_status(:created)
    created = json_body
    expect(created['system_prompt_generated']).to be(true)
    assessment_id = created.dig('assessment', 'id')
    expect(assessment_id).to be_present
    expect(created.dig('assessment', 'name')).to eq(assessment_name)
    expect(created.dig('assessment', 'time_limit_min')).to eq(30)

    # TC-E2E-002 — List contains id AND name
    get '/api/v1/assessments?page=1&per_page=20', headers: headers
    expect(response).to have_http_status(:ok)
    match = json_body['assessments'].find do |a|
      a['id'] == assessment_id && a['name'] == assessment_name
    end
    expect(match).to be_present

    # TC-E2E-003 — Taxonomies feed later add
    get '/api/v1/skill_taxonomies', headers: headers
    expect(response).to have_http_status(:ok)
    taxonomies = json_body['skill_taxonomies']
    expect(taxonomies).not_to be_empty
    tax = taxonomies.find { |s| s['skill_id'] == 'SK-ENG-001' } || taxonomies.first
    tax_skill_id = tax['skill_id']
    tax_skill_label = tax['skill_label']

    # TC-E2E-004 — Show after intervening GET still matches create
    get "/api/v1/assessments/#{assessment_id}", headers: headers
    expect(response).to have_http_status(:ok)
    shown = json_body['assessment']
    expect(shown['id']).to eq(assessment_id)
    expect(shown['name']).to eq(assessment_name)
    expect(shown['time_limit_min']).to eq(30)
    expect(shown['skills']).to eq([])

    # TC-E2E-005 — PUT add taxonomy skill then re-read
    put "/api/v1/assessments/#{assessment_id}",
        params: {
          assessment: {
            name: assessment_name,
            time_limit_min: 30,
            language: 'en',
            assessment_skills_attributes: [
              {
                skill_id: tax_skill_id,
                skill_label: tax_skill_label,
                is_custom: false,
                scope_include: tax['scope_include'],
                scope_exclude: tax['scope_exclude'],
                l1_anchor: tax['l1_anchor'],
                l2_anchor: tax['l2_anchor'],
                l3_anchor: tax['l3_anchor'],
                l4_anchor: tax['l4_anchor'],
                l5_anchor: tax['l5_anchor'],
                expected_level: 3,
                display_order: 1
              }
            ]
          }
        }.to_json,
        headers: headers

    expect(response).to have_http_status(:ok)
    expect(json_body['system_prompt_generated']).to be(true)

    get "/api/v1/assessments/#{assessment_id}", headers: headers
    skills = json_body.dig('assessment', 'skills')
    tax_row = skills.find { |s| s['skill_id'] == tax_skill_id }
    expect(tax_row).to be_present
    expect(tax_row['skill_label']).to eq(tax_skill_label)
    expect(tax_row['is_custom']).to be(false)
    tax_assessment_skill_id = tax_row['id']

    # TC-E2E-006 — PUT add custom skill; taxonomy must remain
    put "/api/v1/assessments/#{assessment_id}",
        params: {
          assessment: {
            name: assessment_name,
            time_limit_min: 30,
            language: 'en',
            assessment_skills_attributes: [
              {
                skill_id: nil,
                skill_label: 'E2E Custom Negotiation',
                is_custom: true,
                scope_include: 'Stakeholder alignment',
                scope_exclude: 'Legal drafting',
                l1_anchor: 'L1 custom',
                l2_anchor: 'L2 custom',
                l3_anchor: 'L3 custom',
                l4_anchor: 'L4 custom',
                l5_anchor: 'L5 custom',
                expected_level: 2,
                display_order: 2
              }
            ]
          }
        }.to_json,
        headers: headers

    expect(response).to have_http_status(:ok)

    get "/api/v1/assessments/#{assessment_id}", headers: headers
    skills = json_body.dig('assessment', 'skills')
    expect(skills.find { |s| s['id'] == tax_assessment_skill_id || s['skill_id'] == tax_skill_id }).to be_present
    custom_row = skills.find { |s| s['skill_label'] == 'E2E Custom Negotiation' }
    expect(custom_row).to be_present
    expect(custom_row['is_custom']).to be(true)
    custom_assessment_skill_id = custom_row['id']

    # TC-E2E-007 — Destroy taxonomy only; custom remains
    put "/api/v1/assessments/#{assessment_id}",
        params: {
          assessment: {
            name: assessment_name,
            time_limit_min: 30,
            language: 'en',
            assessment_skills_attributes: [
              { id: tax_assessment_skill_id, _destroy: true }
            ]
          }
        }.to_json,
        headers: headers

    expect(response).to have_http_status(:ok)

    get "/api/v1/assessments/#{assessment_id}", headers: headers
    skills = json_body.dig('assessment', 'skills')
    expect(skills.find { |s| s['id'] == tax_assessment_skill_id }).to be_nil
    expect(skills.find { |s| s['id'] == custom_assessment_skill_id }).to be_present

    # TC-E2E-008 — Destroy custom; assessment remains, skills empty
    put "/api/v1/assessments/#{assessment_id}",
        params: {
          assessment: {
            name: assessment_name,
            time_limit_min: 30,
            language: 'en',
            assessment_skills_attributes: [
              { id: custom_assessment_skill_id, _destroy: true }
            ]
          }
        }.to_json,
        headers: headers

    expect(response).to have_http_status(:ok)

    get "/api/v1/assessments/#{assessment_id}", headers: headers
    shown = json_body['assessment']
    expect(shown['id']).to eq(assessment_id)
    expect(shown['skills']).to eq([])
    expect(shown['name']).to eq(assessment_name)
  end
  # rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations

  def seed_taxonomy_skill!
    SkillTaxonomy.find_or_create_by!(skill_id: 'SK-ENG-001') do |s|
      s.skill_label = 'React / Frontend Development Core'
      s.category = 'engineering'
      s.scope_include = 'Component design'
      s.scope_exclude = 'Backend APIs'
      s.l1_anchor = 'L1'
      s.l2_anchor = 'L2'
      s.l3_anchor = 'L3'
      s.l4_anchor = 'L4'
      s.l5_anchor = 'L5'
    end
  end
end
