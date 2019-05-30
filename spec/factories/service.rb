FactoryBot.define do
  factory :service do
    entity_id { 'https://not-a-real-entity-id' }
    name  { SecureRandom.alphanumeric }
    component { }
    msa_component { }
  end
end
