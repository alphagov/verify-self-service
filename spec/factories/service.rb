FactoryBot.define do
  factory :service do
    entity_id { SecureRandom.alphanumeric }
    name  { SecureRandom.alphanumeric }
    sp_component { }
    msa_component { }
  end
end
