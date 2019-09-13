FactoryBot.define do
  factory :cert do
    value { PKI.new.generate_encoded_cert(expires_in: 9.months) }

    factory :msa_encryption_certificate, class: Certificate do
      usage { CERTIFICATE_USAGE::ENCRYPTION }
      component { create(:msa_component) }
    end

    factory :sp_encryption_certificate, class: Certificate do
      usage { CERTIFICATE_USAGE::ENCRYPTION }
      component { create(:sp_component) }
    end

    factory :msa_signing_certificate, class: Certificate do
      usage { CERTIFICATE_USAGE::SIGNING }
      component { create(:msa_component) }
    end

    factory :sp_signing_certificate, class: Certificate do
      usage { CERTIFICATE_USAGE::SIGNING }
      component { create(:sp_component) }
    end
  end
<<<<<<< HEAD
end
=======
  factory :vsp_encryption_certificate, class: Certificate do
    usage { CERTIFICATE_USAGE::ENCRYPTION }
    value { PKI.new.generate_encoded_cert(expires_in: 9.months) }
    component { create(:sp_component, vsp: :true) }
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
  factory :vsp_signing_certificate, class: Certificate do
    usage { CERTIFICATE_USAGE::SIGNING }
    value { PKI.new.generate_encoded_cert(expires_in: 9.months) }
    component { create(:sp_component, vsp: :true) }
  end
  factory :sp_signing_certificate, class: Certificate do
    usage { CERTIFICATE_USAGE::SIGNING }
    value { PKI.new.generate_encoded_cert(expires_in: 9.months) }
    component { create(:sp_component) }
  end
end
>>>>>>> XGWgKqpg: Show the clear distinction between the 3 different component types
