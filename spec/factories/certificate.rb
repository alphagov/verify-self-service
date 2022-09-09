FactoryBot.define do
  factory :cert, class: 'Certificate' do
    value { PKI.new.generate_encoded_cert(expires_in: 9.months) }
    in_use_at { nil }
    notification_sent { false }

    factory :msa_encryption_certificate, class: Certificate do
      usage { CERTIFICATE_USAGE::ENCRYPTION }
      component { create(:msa_component) }
    end

    factory :vsp_encryption_certificate, class: Certificate do
      usage { CERTIFICATE_USAGE::ENCRYPTION }
      component { create(:sp_component, vsp: :true) }
    end

    factory :sp_encryption_certificate, class: Certificate do
      usage { CERTIFICATE_USAGE::ENCRYPTION }
      component { create(:sp_component) }
    end

    factory :msa_signing_certificate, class: Certificate do
      usage { CERTIFICATE_USAGE::SIGNING }
      component { create(:msa_component) }
    end

    factory :vsp_signing_certificate, class: Certificate do
      usage { CERTIFICATE_USAGE::SIGNING }
      component { create(:sp_component, vsp: :true) }
    end

    factory :sp_signing_certificate, class: Certificate do
      usage { CERTIFICATE_USAGE::SIGNING }
      component { create(:sp_component) }
    end
  end
end
