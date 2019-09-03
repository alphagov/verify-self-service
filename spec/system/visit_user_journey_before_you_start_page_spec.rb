require 'rails_helper'

RSpec.describe 'Before you start page', type: :system do
  include CertificateSupport

  before(:each) do
    login_certificate_manager_user
  end

  it 'shows before you start page for msa encryption and successfully goes to next page' do
    certificate = create(:msa_encryption_certificate)
    msa_component = certificate.component
    visit before_you_start_path(msa_component.component_type, msa_component.id, msa_component.encryption_certificate_id)
    expect(page).to have_content 'Matching Service Adapter (MSA) encryption certificate'
    click_link 'I have updated my MSA configuration'
    expect(current_path).to eql upload_certificate_path(msa_component.component_type, msa_component.id, msa_component.encryption_certificate_id)
  end

  it 'shows before you start page for sp encryption and successfully goes to next page' do
    certificate = create(:sp_encryption_certificate)
    sp_component = certificate.component
    visit before_you_start_path(sp_component.component_type, sp_component.id, sp_component.encryption_certificate_id)
    expect(page).to have_content 'Verify Service Provider (VSP) encryption certificate'
    click_link 'I have updated my VSP configuration'
    expect(current_path).to eql upload_certificate_path(sp_component.component_type, sp_component.id, sp_component.encryption_certificate_id)
  end

  it 'shows before you start page for msa signing and successfully goes to next page' do
    certificate = create(:msa_signing_certificate)
    msa_component = certificate.component
    visit before_you_start_path(msa_component.component_type, msa_component.id, msa_component.signing_certificates[0])
    expect(page).to have_content 'Matching Service Adapter (MSA) signing certificate'
    click_link 'Continue'
    expect(current_path).to eql upload_certificate_path(msa_component.component_type, msa_component.id, msa_component.signing_certificates[0])
  end

  it 'shows before you start page for sp signing and successfully goes to next page' do
    certificate = create(:sp_signing_certificate)
    msa_component = certificate.component
    visit before_you_start_path(msa_component.component_type, msa_component.id, msa_component.signing_certificates[0])
    expect(page).to have_content 'Verify Service Provider (VSP) signing certificate'
    click_link 'Continue'
    expect(current_path).to eql upload_certificate_path(msa_component.component_type, msa_component.id, msa_component.signing_certificates[0])
  end

end