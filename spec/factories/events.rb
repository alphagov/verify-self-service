FactoryBot.define do
  factory :new_sp_component_event do
    name { SecureRandom.alphanumeric }
    component_type { COMPONENT_TYPE::SP }
    environment { S3::ENVIRONMENT::STAGING }
  end

  factory :new_msa_component_event do
    name { SecureRandom.alphanumeric }
    entity_id { 'https://test-entity-id' }
    environment { S3::ENVIRONMENT::STAGING }
  end

  factory :new_team_event do
    name { 'Team Awesome' }
  end
end
