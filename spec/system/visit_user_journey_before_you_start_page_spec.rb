require 'rails_helper'

RSpec.describe 'Before you start page', type: :system do
  include CertificateSupport

  before(:each) do
    login_certificate_manager_user
  end
  
  let(:msa_component) { create(:msa_component, encryption_certificate_id: 1) }
  let(:sp_component) { create(:sp_component, encryption_certificate_id: 1) }
  let(:root) { PKI.new }
  let(:x509_cert) { root.generate_encoded_cert(expires_in: 9.months) }

  it 'shows before you start page for msa encryption and successfully goes to next page' do
    defaults = {
      usage: CERTIFICATE_USAGE::ENCRYPTION,
      value: x509_cert,
      component: msa_component
    }
    Certificate.create(defaults)
    visit before_you_start_path(msa_component.component_type, msa_component.id, msa_component.encryption_certificate_id)
    expect(page).to have_content 'Matching Service Adapter (MSA) encryption certificate'
    click_link 'I have updated my MSA configuration'
    expect(current_path).to eql upload_certificate_path(msa_component.component_type, msa_component.id, msa_component.encryption_certificate_id)
  end

  it 'shows before you start page for sp encryption and successfully goes to next page' do
    defaults = {
      usage: CERTIFICATE_USAGE::ENCRYPTION,
      value: x509_cert,
      component: sp_component
    }
    Certificate.create(defaults)
    visit before_you_start_path(sp_component.component_type, sp_component.id, sp_component.encryption_certificate_id)
    expect(page).to have_content 'Verify Service Provider (VSP) encryption certificate'
    click_link 'I have updated my VSP configuration'
    expect(current_path).to eql upload_certificate_path(sp_component.component_type, sp_component.id, sp_component.encryption_certificate_id)
  end
end
