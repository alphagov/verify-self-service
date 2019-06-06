FactoryBot.define do
  factory :sp_component do
    component_type { CONSTANTS::SP }
  end

  factory :msa_component do
    component_type { CONSTANTS::MSA }
    entity_id { 'https://test-entity-id'}
  end
end
