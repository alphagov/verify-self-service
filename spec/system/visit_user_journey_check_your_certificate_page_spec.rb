require 'rails_helper'

RSpec.describe 'Check your certificate page', type: :system do
  include CertificateSupport

  let(:msa_encryption_certificate) { create(:msa_encryption_certificate) }
  let(:sp_encryption_certificate) { create(:sp_encryption_certificate) }

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
  end
  context 'shows check your certificate page for' do
    it 'msa encryption and successfully goes to next page' do
      msa_component = msa_encryption_certificate.component
      visit upload_certificate_path(msa_component.component_type, msa_component.id, msa_component.encryption_certificate_id)
      fill_in 'certificate_value', with: msa_encryption_certificate.value
      click_button 'Continue'
      expect(current_path).to eql check_your_certificate_path(msa_component.component_type, msa_component.id, msa_component.encryption_certificate_id)
      expect(page).to have_content 'MSA'
      expect(page).to have_content 'Encryption'
      click_button 'Use this certificate'
      expect(current_path).to eql confirmation_path(msa_component.component_type, msa_component.id, msa_component.encryption_certificate_id)
    end

    it 'sp encryption and successfully goes to next page' do
      sp_component = sp_encryption_certificate.component
      visit upload_certificate_path(sp_component.component_type, sp_component.id, sp_component.encryption_certificate_id)
      fill_in 'certificate_value', with: sp_encryption_certificate.value
      click_button 'Continue'
      expect(current_path).to eql check_your_certificate_path(sp_component.component_type, sp_component.id, sp_component.encryption_certificate_id)
      expect(page).to have_content 'VSP'
      expect(page).to have_content 'Encryption'
      click_button 'Use this certificate'
      expect(current_path).to eql confirmation_path(sp_component.component_type, sp_component.id, sp_component.encryption_certificate_id)
    end
  end
end
