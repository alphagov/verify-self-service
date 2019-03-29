require 'rails_helper'

RSpec.describe ServicesMetadata, type: :model do
  context '#create' do
    root = PKI.new
    signing_cert_1 = root.generate_encoded_cert(expires_in: 2.months)
    it 'is an MSA component with signing and encryption certs' do

      c = Component.create(name: "lala", component_type: "MSA")
      c.certificates.create(usage: "signing", value: signing_cert_1)
      c.certificates.create(usage: "encryption", value: signing_cert_1)

      s = ServicesMetadata.to_json

      expect(s).not_to include("hello")
    end
  end
end
