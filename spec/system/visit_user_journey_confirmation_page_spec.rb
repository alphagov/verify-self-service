require 'rails_helper'

RSpec.describe 'Confirmation page', type: :system do
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

  context 'shows confirmation page for msa' do
    it 'encryption and successfully goes to next page' do
      visit confirmation_path(msa_encryption_certificate.id)
      expect(page).to have_content COMPONENT_TYPE::MSA_SHORT
      expect(page).to have_content 'delete the old encryption key and certificate from your MSA configuration'
      click_link 'Rotate more certificates'
      expect(current_path).to eql root_path
    end

    it 'signing and successfully goes to next page' do
      visit confirmation_path(msa_signing_certificate.id)
      expect(page).to have_content COMPONENT_TYPE::MSA_SHORT
      expect(page).to have_content t('user_journey.confirmation.received_email_to_promote', usage: msa_signing_certificate.usage, component: msa_signing_certificate.component.display)
      click_link 'Rotate more certificates'
      expect(current_path).to eql root_path
    end
  end

  context 'shows confirmation page for vsp' do
    it 'encryption and successfully goes to next page' do
      visit confirmation_path(vsp_encryption_certificate.id)
      expect(page).to have_content COMPONENT_TYPE::VSP_SHORT
      expect(page).to have_content 'delete the old encryption key and certificate from your VSP configuration'
      click_link 'Rotate more certificates'
      expect(current_path).to eql root_path
    end

    it 'signing and successfully goes to next page' do
      visit confirmation_path(vsp_signing_certificate.id)
      expect(page).to have_content COMPONENT_TYPE::VSP_SHORT
      expect(page).to have_content t('user_journey.confirmation.received_email_to_replace', usage: vsp_signing_certificate.usage, component: COMPONENT_TYPE::VSP_SHORT)
      click_link 'Rotate more certificates'
      expect(current_path).to eql root_path
    end
  end

  context 'shows confirmation page for sp' do
    it 'encryption and successfully goes to next page' do
      visit confirmation_path(sp_encryption_certificate.id)
      expect(page).to have_content COMPONENT_TYPE::SP_LONG
      expect(page).to have_content 'delete the old encryption key and certificate from your service provider configuration'
      click_link 'Rotate more certificates'
      expect(current_path).to eql root_path
    end

    it 'signing and successfully goes to next page' do
      visit confirmation_path(sp_signing_certificate.id)
      expect(page).to have_content COMPONENT_TYPE::SP_LONG
      expect(page).to have_content t('user_journey.confirmation.received_email_to_replace', usage: sp_signing_certificate.usage, component: COMPONENT_TYPE::SP_LONG)
      click_link 'Rotate more certificates'
      expect(current_path).to eql root_path
    end

    it 'signing with dual running set to no displays unique content' do
      visit confirmation_path(sp_encryption_certificate.id, true)
      expect(page).to have_content 'Because your service provider does not support dual running'
    end
  end

  context 'fails to publish' do
    before(:each) do
      stub_storage_client_service_error
    end

    it 'displays failed to publish content for MSA encryption certificate' do
      visit upload_certificate_path(msa_encryption_certificate.id)
      fill_in 'certificate_value', with: msa_encryption_certificate.value
      click_button t('user_journey.continue')
      click_button t('user_journey.certificate.use_certificate')

      expect(current_path).to eql confirmation_path(msa_encryption_certificate.id)
      expect(page).to have_content t('user_journey.confirmation.failed_to_publish_heading')
      expect(page).to have_content 'The team will help publish your MSA encryption certificate.'
    end

    it 'displays failed to publish content for VSP encryption certificate' do
      visit upload_certificate_path(vsp_encryption_certificate.id)
      fill_in 'certificate_value', with: vsp_encryption_certificate.value
      click_button t('user_journey.continue')
      click_button t('user_journey.certificate.use_certificate')

      expect(current_path).to eql confirmation_path(vsp_encryption_certificate.id)
      expect(page).to have_content t('user_journey.confirmation.failed_to_publish_heading')
      expect(page).to have_content 'The team will help publish your VSP encryption certificate.'
    end

    it 'displays failed to publish content for MSA signing certificate' do
      visit upload_certificate_path(msa_signing_certificate.id)
      fill_in 'certificate_value', with: msa_signing_certificate.value
      click_button t('user_journey.continue')
      click_button t('user_journey.certificate.use_certificate')
      expect(current_path).to eql confirmation_path(msa_signing_certificate.id)

      expect(page).to have_content t('user_journey.confirmation.failed_to_publish_heading')
      expect(page).to have_content 'The team will help publish your MSA signing certificate.'
    end

    it 'displays failed to publish content for SP signing certificate' do
      visit upload_certificate_path(sp_signing_certificate.id)
      fill_in 'certificate_value', with: sp_signing_certificate.value
      click_button t('user_journey.continue')
      click_button t('user_journey.certificate.use_certificate')

      expect(current_path).to eql confirmation_path(sp_signing_certificate.id)
      expect(page).to have_content t('user_journey.confirmation.failed_to_publish_heading')
      expect(page).to have_content 'The team will help publish your service provider signing certificate.'
    end
  end
end
