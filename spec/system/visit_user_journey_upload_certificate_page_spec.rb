require 'rails_helper'

RSpec.describe 'Upload certificate page', type: :system do
  include CertificateSupport

  let(:msa_encryption_certificate) { create(:msa_encryption_certificate) }
  let(:sp_encryption_certificate) { create(:sp_encryption_certificate) }
  let(:vsp_encryption_certificate) { create(:vsp_encryption_certificate) }

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
      msa_component = msa_encryption_certificate.component
      visit upload_certificate_path(msa_component.component_type, msa_component.id, msa_component.encryption_certificate_id)
      expect(page).to have_content 'MSA'
      expect(page).to have_content 'Upload your new encryption certificate'
      fill_in 'certificate_value', with: msa_encryption_certificate.value
      click_button 'Continue'
      expect(current_path).to eql check_your_certificate_path(msa_component.component_type, msa_component.id, msa_component.encryption_certificate_id)
    end

    it 'signing and successfully goes to next page' do
      certificate = create(:msa_signing_certificate)
      msa_component = certificate.component
      visit upload_certificate_path(msa_component.component_type, msa_component.id, msa_component.signing_certificates[0])
      expect(page).to have_content 'MSA'
      expect(page).to have_content 'Upload your new signing certificate'
      fill_in 'certificate_value', with: certificate.value
      click_button 'Continue'
      expect(current_path).to eql check_your_certificate_path(msa_component.component_type, msa_component.id, msa_component.signing_certificates[0])
    end
  end

  context 'shows upload page for vsp' do
    it 'encryption and successfully goes to next page' do
      vsp_component = vsp_encryption_certificate.component
      visit upload_certificate_path(vsp_component.component_type, vsp_component.id, vsp_component.encryption_certificate_id)
      expect(page).to have_content 'VSP'
      expect(page).to have_content 'Upload your new encryption certificate'
      fill_in 'certificate_value', with: vsp_encryption_certificate.value
      click_button 'Continue'
      expect(current_path).to eql check_your_certificate_path(vsp_component.component_type, vsp_component.id, vsp_component.encryption_certificate_id)
    end

    it 'signing and successfully goes to next page' do
      certificate = create(:vsp_signing_certificate)
      vsp_component = certificate.component
      visit upload_certificate_path(vsp_component.component_type, vsp_component.id, vsp_component.signing_certificates[0])
      expect(page).to have_content 'VSP'
      expect(page).to have_content 'Upload your new signing certificate'
      fill_in 'certificate_value', with: certificate.value
      click_button 'Continue'
      expect(current_path).to eql check_your_certificate_path(vsp_component.component_type, vsp_component.id, vsp_component.signing_certificates[0])
    end
  end

  context 'shows upload page for sp' do
    it 'encryption and successfully goes to next page' do
      sp_component = sp_encryption_certificate.component
      visit upload_certificate_path(sp_component.component_type, sp_component.id, sp_component.encryption_certificate_id)
      expect(page).to have_content 'SP'
      expect(page).to have_content 'Upload your new encryption certificate'
      fill_in 'certificate_value', with: sp_encryption_certificate.value
      click_button 'Continue'
      expect(current_path).to eql check_your_certificate_path(sp_component.component_type, sp_component.id, sp_component.encryption_certificate_id)
    end

    it 'signing and successfully goes to next page' do
      certificate = create(:sp_signing_certificate)
      sp_component = certificate.component
      visit upload_certificate_path(sp_component.component_type, sp_component.id, sp_component.signing_certificates[0])
      expect(page).to have_content 'SP'
      expect(page).to have_content 'Upload your new signing certificate'
      fill_in 'certificate_value', with: certificate.value
      click_button 'Continue'
      expect(current_path).to eql check_your_certificate_path(sp_component.component_type, sp_component.id, sp_component.signing_certificates[0])
    end
  end
end
