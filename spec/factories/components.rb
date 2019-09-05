FactoryBot.define do
  factory :sp_component do
    component_type { COMPONENT_TYPE::SP }
    name { 'Test Service Provider' }
    environment { 'staging' }
  end

  factory :msa_component do
    component_type { COMPONENT_TYPE::MSA }
    entity_id { 'https://test-entity-id' }
    environment { 'staging' }
  end
end
