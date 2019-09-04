FactoryBot.define do
  factory :msa_encryption_certificate, class: Certificate do
    usage { CERTIFICATE_USAGE::ENCRYPTION }
    value { PKI.new.generate_encoded_cert(expires_in: 9.months) }
    component { create(:msa_component) }
  end
  factory :sp_encryption_certificate, class: Certificate do
    usage { CERTIFICATE_USAGE::ENCRYPTION }
    value { PKI.new.generate_encoded_cert(expires_in: 9.months) }
    component { create(:sp_component) }
  end
  factory :msa_signing_certificate, class: Certificate do
    usage { CERTIFICATE_USAGE::SIGNING }
    value { PKI.new.generate_encoded_cert(expires_in: 9.months) }
    component { create(:msa_component) }
  end
  factory :sp_signing_certificate, class: Certificate do
    usage { CERTIFICATE_USAGE::SIGNING }
    value { PKI.new.generate_encoded_cert(expires_in: 9.months) }
    component { create(:sp_component) }
  end
end