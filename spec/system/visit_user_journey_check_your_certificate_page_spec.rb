require 'rails_helper'

RSpec.describe 'Check your certificate page', type: :system do
  include CertificateSupport

  before(:each) do
    login_certificate_manager_user
  end
  
  let(:msa_component) { create(:msa_component, encryption_certificate_id: 1) }
  let(:sp_component) { create(:sp_component, encryption_certificate_id: 1) }
  let(:root) { PKI.new }
  let(:x509_cert) { root.generate_encoded_cert(expires_in: 9.months) }

  it 'shows check your ceritifcate page for msa encryption and successfully goes to next page' do
    defaults = {
      usage: CERTIFICATE_USAGE::ENCRYPTION,
      value: x509_cert,
      component: msa_component
    }
    Certificate.create(defaults)
    visit upload_certificate_path(msa_component.component_type, msa_component.id, msa_component.encryption_certificate_id)
    fill_in 'certificate_value', with: x509_cert
    click_button 'Continue'
    expect(current_path).to eql check_your_certificate_path(msa_component.component_type, msa_component.id, msa_component.encryption_certificate_id)
    expect(page).to have_content 'MSA'
    expect(page).to have_content "Check you've uploaded the right certificate"
    click_button 'Use this certificate'
    expect(current_path).to eql confirmation_path(msa_component.component_type, msa_component.id, msa_component.encryption_certificate_id)
  end

  it 'shows check your ceritifcate page for sp encryption and successfully goes to next page' do
    defaults = {
      usage: CERTIFICATE_USAGE::ENCRYPTION,
      value: x509_cert,
      component: sp_component
    }
    Certificate.create(defaults)
    visit upload_certificate_path(sp_component.component_type, sp_component.id, sp_component.encryption_certificate_id)
    fill_in 'certificate_value', with: x509_cert
    click_button 'Continue'
    expect(current_path).to eql check_your_certificate_path(sp_component.component_type, sp_component.id, sp_component.encryption_certificate_id)
    expect(page).to have_content 'SP'
    expect(page).to have_content "Check you've uploaded the right certificate"
    click_button 'Use this certificate'
    expect(current_path).to eql confirmation_path(sp_component.component_type, sp_component.id, sp_component.encryption_certificate_id)
  end

end
