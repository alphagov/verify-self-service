require 'rails_helper'
require 'json'
RSpec.describe ServicesMetadata, type: :model do
  include CertificateSupport
  context '#create' do
    root = PKI.new
    publish_date = Time.now
    event_id = 4655675
    certificate = root.generate_encoded_cert(expires_in: 2.months)
    it 'is an MSA component with signing and encryption certs' do

      c = Component.create(name: 'lala', component_type: 'MSA')
      c.certificates.create(usage: 'signing', value: certificate)
      c.certificates.create(usage: 'signing', value: certificate)
      c.certificates.create(usage: 'encryption', value: certificate)

      actual_config = ServicesMetadata.to_json(event_id, [c], publish_date)

      expected_config = {
        publish_date: publish_date,
        event_id: 4655675,
        matching_service_adapters: [{
          name: 'lala',
          encryption_certificate: {
            name: root.certificate_subject(certificate),
            value: certificate
          },
          signing_certificate: [{
            name: root.certificate_subject(certificate),
            value: certificate
          }, {
            name: root.certificate_subject(certificate),
            value: certificate
          }]
        }],
        service_providers: []
      }
      expect(actual_config).not_to include('hello')
      expect(actual_config).to include('matching_service_adapters')
      expect(actual_config).to include(expected_config.to_json)
    end
    it 'produces required output structure' do
      c = Component.new
      actual_config = ServicesMetadata.to_json(event_id, [c], publish_date)
      expected_config = {
        publish_date: publish_date,
        event_id: 4655675,
        matching_service_adapters: [],
        service_providers: []
      }
      expect(actual_config).to include('publish_date', 'service_providers')
      expect(actual_config).to include(expected_config.to_json)
    end
  end
end
