require 'rails_helper'

RSpec.describe 'Confirmation page', type: :system do
  include CertificateSupport

  before(:each) do
    login_certificate_manager_user
  end
  
  let(:msa_component) { create(:msa_component, encryption_certificate_id: 1) }
  let(:sp_component) { create(:sp_component, encryption_certificate_id: 1) }
  let(:root) { PKI.new }
  let(:x509_cert) { root.generate_encoded_cert(expires_in: 9.months) }

  it 'shows confirmation page for msa encryption and successfully goes to next page' do
    defaults = {
      usage: CERTIFICATE_USAGE::ENCRYPTION,
      value: x509_cert,
      component: msa_component
    }
    Certificate.create(defaults)
    visit confirmation_path(msa_component.component_type, msa_component.id, msa_component.encryption_certificate_id)
    expect(page).to have_content 'delete the old encryption key and certificate from your MSA configuration'
    click_link 'Rotate more certificates'
    expect(current_path).to eql user_journey_path
  end

  it 'shows confirmation page for sp encryption and successfully goes to next page' do
    defaults = {
      usage: CERTIFICATE_USAGE::ENCRYPTION,
      value: x509_cert,
      component: sp_component
    }
    Certificate.create(defaults)
    visit confirmation_path(sp_component.component_type, sp_component.id, sp_component.encryption_certificate_id)
    expect(page).to have_content 'delete the old encryption key and certificate from your VSP configuration'
    click_link 'Rotate more certificates'
    expect(current_path).to eql user_journey_path
  end
end
