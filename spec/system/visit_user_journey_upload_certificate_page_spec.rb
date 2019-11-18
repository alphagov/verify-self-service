require 'rails_helper'

RSpec.describe 'Upload certificate page', type: :system do
  include CertificateSupport

  let(:user) { login_certificate_manager_user }
  let(:msa_encryption_certificate) { create(:msa_encryption_certificate, component: create(:msa_component, team_id: user.team)) }
  let(:sp_encryption_certificate) { create(:sp_encryption_certificate, component: create(:sp_component, team_id: user.team)) }
  let(:vsp_encryption_certificate) { create(:vsp_encryption_certificate, component: create(:sp_component, vsp: true, team_id: user.team)) }
  let(:msa_signing_certificate) { create(:msa_signing_certificate, component: create(:msa_component, team_id: user.team)) }
  let(:sp_signing_certificate) { create(:sp_signing_certificate, component: create(:sp_component, team_id: user.team)) }
  let(:vsp_signing_certificate) { create(:vsp_signing_certificate, component: create(:sp_component, vsp: true, team_id: user.team)) }

  before(:each) do
    login_certificate_manager_user
    ReplaceEncryptionCertificateEvent.create(
      component: sp_encryption_certificate.component,
      encryption_certificate_id: sp_encryption_certificate.id
    )
    ReplaceEncryptionCertificateEvent.create(
      component: msa_encryption_certificate.component,
      encryption_certificate_id: msa_encryption_certificate.id
    )
    ReplaceEncryptionCertificateEvent.create(
      component: vsp_encryption_certificate.component,
      encryption_certificate_id: vsp_encryption_certificate.id
    )
  end

  context 'shows upload page for msa' do
    it 'encryption and successfully goes to next page' do
      visit upload_certificate_path(msa_encryption_certificate.id)
      expect(page).to have_content COMPONENT_TYPE::MSA_SHORT
      expect(page).to have_content 'Upload your new encryption certificate'
      fill_in 'certificate_value', with: msa_encryption_certificate.value
      click_button 'Continue'
      expect(current_path).to eql check_your_certificate_path(msa_encryption_certificate.id)
    end

    it 'signing and successfully goes to next page' do
      visit upload_certificate_path(msa_signing_certificate.id)
      expect(page).to have_content COMPONENT_TYPE::MSA_SHORT
      expect(page).to have_content 'Upload your new signing certificate'
      fill_in 'certificate_value', with: msa_signing_certificate.value
      click_button 'Continue'
      expect(current_path).to eql check_your_certificate_path(msa_signing_certificate.id)
    end
  end

  context 'shows upload page for vsp' do
    it 'encryption and successfully goes to next page' do
      visit upload_certificate_path(vsp_encryption_certificate.id)
      expect(page).to have_content COMPONENT_TYPE::VSP_SHORT
      expect(page).to have_content 'Upload your new encryption certificate'
      fill_in 'certificate_value', with: vsp_encryption_certificate.value
      click_button 'Continue'
      expect(current_path).to eql check_your_certificate_path(vsp_encryption_certificate.id)
    end

    it 'signing and successfully goes to next page' do
      visit upload_certificate_path(vsp_signing_certificate.id)
      expect(page).to have_content COMPONENT_TYPE::VSP_SHORT
      expect(page).to have_content 'Upload your new signing certificate'
      fill_in 'certificate_value', with: vsp_signing_certificate.value
      click_button 'Continue'
      expect(current_path).to eql check_your_certificate_path(vsp_signing_certificate.id)
    end
  end

  context 'shows upload page for sp' do
    it 'encryption and successfully goes to next page' do
      visit upload_certificate_path(sp_encryption_certificate.id)
      expect(page).to have_content 'Service provider'
      expect(page).to have_content 'Upload your new encryption certificate'
      fill_in 'certificate_value', with: sp_encryption_certificate.value
      click_button 'Continue'
      expect(current_path).to eql check_your_certificate_path(sp_encryption_certificate.id)
    end

    it 'signing and successfully goes to next page' do
      visit upload_certificate_path(sp_signing_certificate.id)
      expect(page).to have_content 'Service provider'
      expect(page).to have_content 'Upload your new signing certificate'
      fill_in 'certificate_value', with: sp_signing_certificate.value
      click_button 'Continue'
      expect(current_path).to eql check_your_certificate_path(sp_signing_certificate.id)
    end
  end
end
