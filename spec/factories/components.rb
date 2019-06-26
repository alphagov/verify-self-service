FactoryBot.define do
  factory :sp_component do
    component_type { COMPONENT_TYPE::SP }
  end

  factory :msa_component do
    component_type { COMPONENT_TYPE::MSA }
    entity_id { 'https://test-entity-id'}
  end
end
