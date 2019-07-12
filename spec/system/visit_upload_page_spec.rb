require 'rails_helper'

RSpec.describe 'UploadPage', type: :system do
  include CertificateSupport

  before(:each) do
    login_user
  end

  entity_id = 'http://test-entity-id'
  component_params = { name: 'fake_name', entity_id: entity_id }
  let(:component) { NewMsaComponentEvent.create(component_params).msa_component }
  let(:root) { PKI.new }
  let(:test_certificate) { root.generate_encoded_cert(expires_in: 2.months) }

  it 'successfully submits a certificate' do
    visit new_msa_component_certificate_path(component)
    choose 'certificate_usage_signing', allow_label_click: true
    fill_in 'certificate_value', with: test_certificate
    click_button 'Upload'
    expect(page).to have_selector "#edit_certificate_#{component.certificates.last.id}"
    expect(current_path).to eql msa_component_path(component)
  end
end
