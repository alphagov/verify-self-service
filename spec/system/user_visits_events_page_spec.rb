require 'rails_helper'
require 'auth_test_helper'

RSpec.describe 'the events page', type: :system do
  include CertificateSupport

  before(:each) do
    stub_auth
  end
  entity_id = 'http://test-entity-id'
  component_params = { component_type: 'MSA', name: 'fake_name', entity_id: entity_id }
  let(:component) { NewComponentEvent.create(component_params).component }
  let(:root) { PKI.new }

  it 'there are some events' do
    good_cert_1 = root.generate_encoded_cert(expires_in: 2.months)
    good_cert_2 = root.generate_encoded_cert(expires_in: 2.months)
    good_cert_3 = root.generate_encoded_cert(expires_in: 2.months)

    UploadCertificateEvent.create(usage: CONSTANTS::SIGNING, value: good_cert_1, component_id: component.id)
    UploadCertificateEvent.create(usage: CONSTANTS::SIGNING, value: good_cert_2, component_id: component.id)
    UploadCertificateEvent.create(usage: CONSTANTS::SIGNING, value: good_cert_3, component_id: component.id)

    visit events_path
    expect(page).to have_content good_cert_1
    expect(page).to have_content good_cert_2
    expect(page).to have_content good_cert_3
  end

  it 'is paginated' do
    55.times.each do
      UploadCertificateEvent.create(usage: CONSTANTS::SIGNING, value: root.generate_encoded_cert(expires_in: 2.months), component_id: component.id)
    end

    visit events_path
    expect(page).to have_selector('tbody tr', count: 25)

    click_on 'Next ›'
    expect(page).to have_selector('tbody tr', count: 25)
  end
end
