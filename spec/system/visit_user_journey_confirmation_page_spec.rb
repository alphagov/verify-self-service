require 'rails_helper'

RSpec.describe 'Confirmation page', type: :system do
  include CertificateSupport

  before(:each) do
    login_certificate_manager_user
  end

  it 'shows confirmation page for msa encryption and successfully goes to next page' do
    certificate = create(:msa_encryption_certificate)
    msa_component = certificate.component
    visit confirmation_path(msa_component.component_type, msa_component.id, msa_component.encryption_certificate_id)
    expect(page).to have_content 'MSA'
    expect(page).to have_content 'Encryption'
    click_link 'Rotate more certificates'
    expect(current_path).to eql user_journey_path
  end

  it 'shows confirmation page for sp encryption and successfully goes to next page' do
    certificate = create(:sp_encryption_certificate)
    sp_component = certificate.component
    visit confirmation_path(sp_component.component_type, sp_component.id, sp_component.encryption_certificate_id)
    expect(page).to have_content 'SP'
    expect(page).to have_content 'Encryption'
    click_link 'Rotate more certificates'
    expect(current_path).to eql user_journey_path
  end

  it 'shows confirmation page for msa signing and successfully goes to next page' do
    certificate = create(:msa_signing_certificate)
    msa_component = certificate.component
    visit confirmation_path(msa_component.component_type, msa_component.id, msa_component.signing_certificates[0])
    expect(page).to have_content 'MSA'
    expect(page).to have_content 'Signing'
    click_link 'Rotate more certificates'
    expect(current_path).to eql user_journey_path
  end

  it 'shows confirmation page for sp signing and successfully goes to next page' do
    certificate = create(:sp_signing_certificate)
    sp_component = certificate.component
    visit confirmation_path(sp_component.component_type, sp_component.id, sp_component.signing_certificates[0])
    expect(page).to have_content 'SP'
    expect(page).to have_content 'Signing'
    click_link 'Rotate more certificates'
    expect(current_path).to eql user_journey_path
  end
end
