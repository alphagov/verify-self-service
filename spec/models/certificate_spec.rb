require 'rails_helper'

include CertificateSupport

RSpec.describe Certificate, type: :model do

  let(:good_cert_value) {
    root = PKI.new
    root.generate_signed_cert(expires_in: 2.months).to_pem
  }

  component_params = { component_type: 'MSA', name:'fake_name' }
  let(:component){ NewComponentEvent.create(component_params).component}
  it "is valid with valid attributes" do

    expect(Certificate.new(usage: 'signing', value: good_cert_value, component_id: component.id)).to be_valid
    expect(Certificate.new(usage: 'encryption', value: good_cert_value, component_id:component.id)).to be_valid
  end

  it "is not valid with non-valid attributes" do

    expect(Certificate.new(usage: 'blah', value: good_cert_value, component_id:component.id)).to_not be_valid
  end

  it "is not valid without a usage and/or value" do

    expect(Certificate.new(usage: nil, value: good_cert_value, component_id: component.id)).to_not be_valid
    expect(Certificate.new(usage: 'signing', value: nil, component_id: component.id)).to_not be_valid
    expect(Certificate.new(usage: nil, value: nil, component_id: component.id)).to_not be_valid
  end

  it 'has events' do
    event = UploadCertificateEvent.create!(usage: 'signing', value: good_cert_value, component_id: component.id)
    certificate = event.certificate
    expect([certificate.events.last]).to eql [event]
  end
end
