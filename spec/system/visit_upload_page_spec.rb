require 'rails_helper'
require 'auth_test_helper'

RSpec.describe 'UploadPage', type: :system do
  include CertificateSupport

  before(:each) do
    stub_auth
  end

  entity_id = 'http://test-entity-id'
  component_params = { component_type: 'MSA', name: 'fake_name', entity_id: entity_id }
  let(:component) { NewComponentEvent.create(component_params).component }
  let(:root) { PKI.new }
  let(:test_certificate) { root.generate_encoded_cert(expires_in: 2.months) }

  it 'successfully submits a certificate' do
    visit new_component_certificate_path(component)
    choose 'certificate_usage_signing', allow_label_click: true
    fill_in 'certificate_value', with: test_certificate
    click_button 'Upload'
    expect(page).to have_selector "#edit_certificate_#{component.certificates.last.id}"
    expect(current_path).to eql component_path(component)
  end
end
