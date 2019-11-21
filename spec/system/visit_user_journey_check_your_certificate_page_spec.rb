require 'rails_helper'

RSpec.describe 'Check your certificate page', type: :system do
  include CertificateSupport

  let(:user) { login_certificate_manager_user }
  let(:msa_encryption_certificate) { create(:msa_encryption_certificate, component: create(:msa_component, team_id: user.team)) }
  let(:sp_encryption_certificate) { create(:sp_encryption_certificate, component: create(:sp_component, team_id: user.team)) }
  let(:vsp_encryption_certificate) { create(:vsp_encryption_certificate, component: create(:sp_component, vsp: true, team_id: user.team)) }
  let(:msa_signing_certificate) { create(:msa_signing_certificate, component: create(:msa_component, team_id: user.team)) }
  let(:sp_signing_certificate) { create(:sp_signing_certificate, component: create(:sp_component, team_id: user.team)) }
  let(:vsp_signing_certificate) { create(:vsp_signing_certificate, component: create(:sp_component, vsp: true, team_id: user.team)) }

  before(:each) do
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

  context 'encryption journey' do
    it 'msa encryption and successfully goes to next page' do
      visit upload_certificate_path(msa_encryption_certificate.id)
      fill_in 'certificate_value', with: msa_encryption_certificate.value
      click_button 'Continue'
      expect(current_path).to eql check_your_certificate_path(msa_encryption_certificate.id)
      expect(page).to have_content COMPONENT_TYPE::MSA_SHORT
      expect(page).to have_content 'Encryption'
      click_button 'Use this certificate'
      expect(current_path).to eql confirmation_path(msa_encryption_certificate.id)
    end

    it 'vsp encryption and successfully goes to next page' do
      visit upload_certificate_path(vsp_encryption_certificate.id)
      fill_in 'certificate_value', with: vsp_encryption_certificate.value
      click_button 'Continue'
      expect(current_path).to eql check_your_certificate_path(vsp_encryption_certificate.id)
      expect(page).to have_content COMPONENT_TYPE::VSP_SHORT
      expect(page).to have_content 'Encryption'
      click_button 'Use this certificate'
      expect(current_path).to eql confirmation_path(vsp_encryption_certificate.id)
    end

    it 'sp encryption and successfully goes to next page' do
      visit upload_certificate_path(sp_encryption_certificate.id)
      fill_in 'certificate_value', with: sp_encryption_certificate.value
      click_button 'Continue'
      expect(current_path).to eql check_your_certificate_path(sp_encryption_certificate.id)
      expect(page).to have_content COMPONENT_TYPE::SP_LONG
      expect(page).to have_content 'Encryption'
      click_button 'Use this certificate'
      expect(current_path).to eql confirmation_path(sp_encryption_certificate.id)
    end

    it 'unsuccessfully publishes certificate' do
      stub_storage_client_service_error
      visit upload_certificate_path(sp_encryption_certificate.id)
      fill_in 'certificate_value', with: sp_encryption_certificate.value
      click_button 'Continue'
      expect(current_path).to eql check_your_certificate_path(sp_encryption_certificate.id)
      expect(page).to have_content COMPONENT_TYPE::SP_LONG
      expect(page).to have_content 'Encryption'
      click_button 'Use this certificate'
      expect(current_path).to eql confirmation_path(sp_encryption_certificate.id)
      expect(page).to have_content t('user_journey.confirmation.failed_to_publish_heading')
    end

    it 'sp encryption journey with dual running set to no displays unique content' do
      visit upload_certificate_path(sp_encryption_certificate.id, true)
      fill_in 'certificate_value', with: sp_encryption_certificate.value
      click_button 'Continue'
      expect(current_path).to eql check_your_certificate_path(sp_encryption_certificate.id, true)
      expect(page).to have_content 'Because your service provider does not support dual running, your connection will break when the GOV.UK Verify Hub starts using your new certificate.'
    end
  end

  context 'signing journey' do
    it 'expect msa component, signing certificate and successfully goes to next page' do
      visit upload_certificate_path(msa_signing_certificate.id)
      fill_in 'certificate_value', with: msa_signing_certificate.value
      click_button 'Continue'
      expect(current_path).to eql check_your_certificate_path(msa_signing_certificate.id)
      expect(page).to have_content COMPONENT_TYPE::MSA_SHORT
      expect(page).to have_content 'Signing'
      click_button 'Use this certificate'
      expect(current_path).to eql confirmation_path(msa_signing_certificate.id)
    end

    it 'expect vsp component, signing certificate and successfully goes to next page' do
      visit upload_certificate_path(vsp_signing_certificate.id)
      fill_in 'certificate_value', with: vsp_signing_certificate.value
      click_button 'Continue'
      expect(current_path).to eql check_your_certificate_path(vsp_signing_certificate.id)
      expect(page).to have_content COMPONENT_TYPE::VSP_SHORT
      expect(page).to have_content 'Signing'
      click_button 'Use this certificate'
      expect(current_path).to eql confirmation_path(vsp_signing_certificate.id)
    end

    it 'expect sp component, signing certificate and successfully goes to next page' do
      visit upload_certificate_path(sp_signing_certificate.id)
      fill_in 'certificate_value', with: sp_signing_certificate.value
      click_button 'Continue'
      expect(current_path).to eql check_your_certificate_path(sp_signing_certificate.id)
      expect(page).to have_content t('user_journey.certificate.signed_mesages_from_your_service')
      expect(page).to have_content 'Signing'
      click_button 'Use this certificate'
      expect(current_path).to eql confirmation_path(sp_signing_certificate.id)
    end
  end
end
