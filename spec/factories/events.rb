FactoryBot.define do
  factory :new_sp_component_event do
    name { SecureRandom.alphanumeric }
    component_type { CONSTANTS::SP }
  end

  factory :new_msa_component_event do
    name { SecureRandom.alphanumeric }
    entity_id { 'https://test-entity-id' }
  end
end
