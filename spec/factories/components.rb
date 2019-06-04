FactoryBot.define do
  factory :sp_component do
    component_type { 'VSP' }
  end

  factory :msa_component do
    component_type { 'MSA' }
    entity_id { 'https://test-entity-id'}
  end
end
