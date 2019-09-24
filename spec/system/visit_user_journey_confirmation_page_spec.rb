require 'rails_helper'

RSpec.describe 'Confirmation page', type: :system do
  include CertificateSupport

  let(:user) { login_certificate_manager_user }
  let(:msa_encryption_certificate) { create(:msa_encryption_certificate, component: create(:msa_component, team_id: user.team)) }
  let(:sp_encryption_certificate) { create(:sp_encryption_certificate, component: create(:sp_component, team_id: user.team)) }
  let(:vsp_encryption_certificate) { create(:vsp_encryption_certificate, component: create(:sp_component, vsp: true, team_id: user.team)) }

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
      msa_component = msa_encryption_certificate.component
      visit confirmation_path(msa_component.component_type, msa_component.id, msa_component.encryption_certificate_id)
      expect(page).to have_content COMPONENT_TYPE::MSA_SHORT
      expect(page).to have_content 'delete the old encryption key and certificate from your MSA configuration'
      click_link 'Rotate more certificates'
      expect(current_path).to eql root_path
    end

    it 'signing and successfully goes to next page' do
      certificate = create(:msa_signing_certificate, component: create(:msa_component, team_id: user.team))
      msa_component = certificate.component
      visit confirmation_path(msa_component.component_type, msa_component.id, msa_component.signing_certificates[0])
      expect(page).to have_content COMPONENT_TYPE::MSA_SHORT
      expect(page).to have_content 'delete the old signing key and certificate from your MSA configuration'
      click_link 'Rotate more certificates'
      expect(current_path).to eql root_path
    end
  end

  context 'shows confirmation page for vsp' do
    it 'encryption and successfully goes to next page' do
      vsp_component = vsp_encryption_certificate.component
      visit confirmation_path(vsp_component.component_type, vsp_component.id, vsp_component.encryption_certificate_id)
      expect(page).to have_content COMPONENT_TYPE::VSP_SHORT
      expect(page).to have_content 'delete the old encryption key and certificate from your VSP configuration'
      click_link 'Rotate more certificates'
      expect(current_path).to eql root_path
    end

    it 'signing and successfully goes to next page' do
      certificate = create(:vsp_signing_certificate, component: create(:sp_component, vsp: true, team_id: user.team))
      vsp_component = certificate.component
      visit confirmation_path(vsp_component.component_type, vsp_component.id, vsp_component.signing_certificates[0])
      expect(page).to have_content COMPONENT_TYPE::VSP_SHORT
      expect(page).to have_content 'delete the old signing key and certificate from your VSP configuration'
      click_link 'Rotate more certificates'
      expect(current_path).to eql root_path
    end
  end

  context 'shows confirmation page for sp' do
    it 'encryption and successfully goes to next page' do
      sp_component = sp_encryption_certificate.component
      visit confirmation_path(sp_component.component_type, sp_component.id, sp_component.encryption_certificate_id)
      expect(page).to have_content 'service provider'
      expect(page).to have_content 'delete the old encryption key and certificate from your service provider configuration'
      click_link 'Rotate more certificates'
      expect(current_path).to eql root_path
    end

    it 'signing and successfully goes to next page' do
      certificate = create(:sp_signing_certificate, component: create(:sp_component, team_id: user.team))
      sp_component = certificate.component
      visit confirmation_path(sp_component.component_type, sp_component.id, sp_component.signing_certificates[0])
      expect(page).to have_content 'service provider'
      expect(page).to have_content 'delete the old signing key and certificate from your service provider configuration'
      click_link 'Rotate more certificates'
      expect(current_path).to eql root_path
    end

    it 'signing with dual running set to no displays unique content' do
      sp_component = sp_encryption_certificate.component
      visit confirmation_path(sp_component.component_type, sp_component.id, sp_component.encryption_certificate_id, 'no')
      expect(page).to have_content 'Because your service provider does not support dual running'
    end
  end
end
