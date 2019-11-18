require 'rails_helper'

RSpec.describe 'Before you start page', type: :system do
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

  context 'encryption journey' do 
    it 'shows before you start page for msa encryption and successfully goes to next page' do
      visit before_you_start_path(msa_encryption_certificate.id)
      expect(page).to have_content 'Matching Service Adapter (MSA) encryption certificate'
      click_link 'I have updated my MSA configuration'
      expect(current_path).to eql upload_certificate_path(msa_encryption_certificate.id)
    end

    it 'shows before you start page for vsp encryption and successfully goes to next page' do
      visit before_you_start_path(vsp_encryption_certificate.id)
      expect(page).to have_content 'Verify Service Provider (VSP) encryption certificate'
      click_link 'I have updated my VSP configuration'
      expect(current_path).to eql upload_certificate_path(vsp_encryption_certificate.id)
    end

    it 'shows before you start page for sp encryption and successfully goes to next page' do
      visit before_you_start_path(sp_encryption_certificate.id)
      expect(page).to have_content 'service provider encryption certificate'
      click_link 'I have updated my service provider configuration'
      expect(current_path).to eql upload_certificate_path(sp_encryption_certificate.id)
    end

    it 'sp encryption journey with dual running set to no displays unqiue content' do
      visit before_you_start_path(sp_encryption_certificate.id, true)
      expect(page).to have_content 'Because your service provider does not support dual running, there will be an outage when you rotate the encryption key.'
    end
  end

  context 'signing journey' do
    it 'shows before you start page for msa signing and successfully goes to next page' do
      visit before_you_start_path(msa_signing_certificate.id)
      expect(page).to have_content 'Matching Service Adapter (MSA) signing certificate'
      click_link t('user_journey.before_you_start.have_updated', component: msa_signing_certificate.component.display)
      expect(current_path).to eql upload_certificate_path(msa_signing_certificate.id)
    end

    it 'shows before you start page for vsp signing and successfully goes to next page' do
      visit before_you_start_path(vsp_signing_certificate.id)
      expect(page).to have_content 'Verify Service Provider (VSP) signing certificate'
      click_link 'Continue'
      expect(current_path).to eql upload_certificate_path(vsp_signing_certificate.id)
    end

    it 'shows before you start page for sp signing and successfully goes to next page' do
      visit before_you_start_path(sp_signing_certificate.id)
      expect(page).to have_content 'service provider signing certificate'
      click_link 'Continue'
      expect(current_path).to eql upload_certificate_path(sp_signing_certificate.id)
    end
  end
end
