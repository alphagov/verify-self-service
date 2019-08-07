require 'rails_helper'

RSpec.describe 'the events page', type: :system do
  include CertificateSupport
  entity_id = 'http://test-entity-id'
  component_params = { name: 'fake_name', entity_id: entity_id }
  let(:component) { NewMsaComponentEvent.create(component_params).msa_component }
  let(:root) { PKI.new }
  before(:each) do
    login_user
  end

  it 'there are some events' do
    good_cert_1 = root.generate_encoded_cert(expires_in: 2.months)
    good_cert_2 = root.generate_encoded_cert(expires_in: 2.months)
    good_cert_3 = root.generate_encoded_cert(expires_in: 2.months)

    UploadCertificateEvent.create(usage: CERTIFICATE_USAGE::SIGNING, value: good_cert_1, component: component)
    UploadCertificateEvent.create(usage: CERTIFICATE_USAGE::SIGNING, value: good_cert_2, component: component)
    UploadCertificateEvent.create(usage: CERTIFICATE_USAGE::SIGNING, value: good_cert_3, component: component)

    visit admin_events_path
    expect(page).to have_content good_cert_1
    expect(page).to have_content good_cert_2
    expect(page).to have_content good_cert_3
  end

  it 'is paginated' do
    55.times.each do
      UploadCertificateEvent.create(usage: CERTIFICATE_USAGE::SIGNING, value: root.generate_encoded_cert(expires_in: 2.months), component: component)
    end

    visit admin_events_path
    expect(page).to have_selector('tbody tr', count: 25)

    click_on 'Next ›'
    expect(page).to have_selector('tbody tr', count: 25)
  end
end
