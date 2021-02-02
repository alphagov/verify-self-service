FactoryBot.define do

  factory :sp_component do
    component_type { COMPONENT_TYPE::SP }
    name { 'Test Service Provider' }
    team_id { create(:team).id }
    environment { 'staging' }
  end

  factory :msa_component do
    component_type { COMPONENT_TYPE::MSA }
    name { 'Test MSA'}
    entity_id { SecureRandom.alphanumeric }
    team_id { create(:team).id }
    environment { 'staging' }
  end
end
