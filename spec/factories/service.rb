FactoryBot.define do
  factory :service do
    entity_id { 'https://not-a-real-entity-id' }
    name  { SecureRandom.alphanumeric }
    sp_component { }
    msa_component { }
  end
end
