require 'rails_helper'
require 'json'
RSpec.describe Component, type: :model do
  include CertificateSupport
  context '#to_service_metadata' do
    before(:each) do
      Component.destroy_all
    end
    let(:root) { PKI.new }
    let(:published_at) { Time.now }
    let(:event_id) { 0 }
    let(:certificate) { root.generate_encoded_cert(expires_in: 2.months) }
    it 'is an MSA component with signing and encryption certs' do

      c = Component.create(name: 'lala', component_type: 'MSA')
      c.certificates.create(usage: 'signing', value: certificate)
      c.certificates.create(usage: 'signing', value: certificate)
      c.certificates.create(usage: 'encryption', value: certificate)

      actual_config = Component.to_service_metadata(event_id, published_at)

      expected_config = {
        published_at: published_at,
        event_id: event_id,
        matching_service_adapters: [{
          name: 'lala',
          encryption_certificate: {
            name: certificate_subject(certificate),
            value: certificate
          },
          signing_certificates: [{
            name: certificate_subject(certificate),
            value: certificate
          }, {
            name: certificate_subject(certificate),
            value: certificate
          }]
        }],
        service_providers: []
      }
 
      expect(actual_config).to include(:matching_service_adapters)
      expect(actual_config).to include(expected_config)
    end
    it 'produces required output structure' do
      Component.destroy_all
      actual_config = Component.to_service_metadata(event_id, published_at)
      expected_config = {
        published_at: published_at,
        event_id: event_id,
        matching_service_adapters: [],
        service_providers: []
      }
      expect(actual_config).to include(:published_at, :service_providers)
      expect(actual_config).to eq(expected_config)
    end
  end
end
