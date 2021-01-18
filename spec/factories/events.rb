FactoryBot.define do
  factory :new_sp_component_event do
    name { SecureRandom.alphanumeric }
    component_type { COMPONENT_TYPE::SP }
    team_id { create(:team).id }
    environment { 'staging' }
  end

  factory :new_msa_component_event do
    name { SecureRandom.alphanumeric }
    entity_id { SecureRandom.alphanumeric }
    team_id { create(:team).id }
    environment { 'staging' }
  end

  factory :new_team_event do
    name { SecureRandom.alphanumeric }
  end

  factory :delete_team_event do
    team { create(:team) }
  end

  factory :delete_component_event do
    component { create(:new_sp_component_event) }
  end

  factory :delete_service_event do
    service { create(:service) }
  end

  factory :change_service_event do
    service { create(:service) }
  end

  factory :replace_encryption_certificate_event do
    component { create(:sp_component) }
    encryption_certificate_id { create(:sp_encryption_certificate).id }
  end

  factory :upload_certificate_event do
    usage { CERTIFICATE_USAGE::SIGNING }
    value { PKI.new.generate_encoded_cert(expires_in: 9.months) }
    component { create(:sp_component) }
  end

  factory :assign_sp_component_to_service_event do
    service { create(:service) }
    sp_component_id { create(:sp_component).id }
  end

  factory :assign_msa_component_to_service_event do
    service { create(:service) }
    msa_component_id { create(:msa_component).id }
  end

  factory :certificate_in_use_event do
    certificate { create(:sp_signing_certificate) }
  end

  factory :certificate_notification_sent_event do
    certificate { create(:sp_signing_certificate) }
  end
end
