require 'rails_helper'

RSpec.describe 'View certificate page', type: :system do
  include CertificateSupport

  before(:each) do
    login_certificate_manager_user
  end

  it 'shows existing msa encryption certificate information and successfully goes to next page' do
    certificate = create(:msa_encryption_certificate)
    msa_component = certificate.component
    visit view_certificate_path(msa_component.component_type, msa_component.id, msa_component.encryption_certificate_id)
    expect(page).to have_content 'Matching Service Adapter: encryption certificate'
    click_link 'Replace certificate'
    expect(current_path).to eql before_you_start_path(msa_component.component_type, msa_component.id, msa_component.encryption_certificate_id)
  end

  it 'shows existing vsp encryption certificate information and successfully goes to next page' do
    certificate = create(:sp_encryption_certificate)
    sp_component = certificate.component
    visit view_certificate_path(sp_component.component_type, sp_component.id, sp_component.encryption_certificate_id)
    expect(page).to have_content 'Verify Service Provider: encryption certificate'
    click_link 'Replace certificate'
    expect(current_path).to eql before_you_start_path(sp_component.component_type, sp_component.id, sp_component.encryption_certificate_id)
  end

  it 'shows existing msa signing certificate information and successfully goes to next page' do
    certificate = create(:msa_signing_certificate)
    msa_component = certificate.component
    visit view_certificate_path(msa_component.component_type, msa_component.id, msa_component.signing_certificates[0])
    expect(page).to have_content 'Matching Service Adapter: signing certificate'
    click_link 'Add new certificate'
    expect(current_path).to eql before_you_start_path(msa_component.component_type, msa_component.id, msa_component.signing_certificates[0])
  end

  it 'shows existing vsp signing certificate information and successfully goes to next page' do
    certificate = create(:sp_signing_certificate)
    sp_component = certificate.component
    visit view_certificate_path(sp_component.component_type, sp_component.id, sp_component.signing_certificates[0])
    expect(page).to have_content 'Verify Service Provider: signing certificate'
    click_link 'Add new certificate'
    expect(current_path).to eql before_you_start_path(sp_component.component_type, sp_component.id, sp_component.signing_certificates[0])
  end
end
