require 'rails_helper'

RSpec.describe 'View certificate page', type: :system do
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

  context 'shows existing msa' do
    it 'encryption certificate information and navigates to next page if not being deployed' do
      msa_component = msa_encryption_certificate.component
      travel_to Time.now + 11.minutes
      visit view_certificate_path(msa_component.component_type, msa_component.id, msa_component.encryption_certificate_id)
      expect(page).to have_content 'Matching Service Adapter: encryption certificate'
      click_link 'Replace certificate'
      expect(current_path).to eql before_you_start_path(msa_component.component_type, msa_component.id, msa_component.encryption_certificate_id)
    end

    it 'encryption certificate information and warning when being deployed' do
      msa_component = msa_encryption_certificate.component
      visit view_certificate_path(msa_component.component_type, msa_component.id, msa_component.encryption_certificate_id)
      expect(page).to have_content t('user_journey.replacing_certificate_in_config')
      expect(page).to have_content 'Matching Service Adapter: encryption certificate'
      expect(page).not_to have_content t('user_journey.certificate.replace')
    end

    it 'signing certificate information and navigates to next page' do
      msa_signing_certificate = create(:msa_signing_certificate, component: create(:msa_component, team_id: user.team))
      msa_component = msa_signing_certificate.component
      visit view_certificate_path(msa_component.component_type, msa_component.id, msa_component.signing_certificates[0])
      expect(page).to have_content 'Matching Service Adapter: signing certificate'
      click_link 'Add new certificate'
      expect(current_path).to eql before_you_start_path(msa_component.component_type, msa_component.id, msa_component.signing_certificates[0])
    end
  end

  context 'shows existing vsp' do
    it 'encryption certificate information and navigates to next page' do
      travel_to Time.now + 11.minutes
      vsp_component = vsp_encryption_certificate.component
      visit view_certificate_path(vsp_component.component_type, vsp_component.id, vsp_component.encryption_certificate_id)
      expect(page).to have_content 'Verify Service Provider: encryption certificate'
      click_link 'Replace certificate'
      expect(current_path).to eql before_you_start_path(vsp_component.component_type, vsp_component.id, vsp_component.encryption_certificate_id)
    end

    it 'signing certificate information and navigates to next page' do
      vsp_signing_certificate = create(:vsp_signing_certificate, component: create(:sp_component, vsp: true, team_id: user.team))
      vsp_component = vsp_signing_certificate.component
      visit view_certificate_path(vsp_component.component_type, vsp_component.id, vsp_component.signing_certificates[0])
      expect(page).to have_content 'Verify Service Provider: signing certificate'
      click_link 'Add new certificate'
      expect(current_path).to eql before_you_start_path(vsp_component.component_type, vsp_component.id, vsp_component.signing_certificates[0])
    end
  end

  context 'shows existing sp' do
    it 'encryption certificate information and navigates to next page' do
      travel_to Time.now + 11.minutes
      sp_component = sp_encryption_certificate.component
      visit view_certificate_path(sp_component.component_type, sp_component.id, sp_component.encryption_certificate_id)
      expect(page).to have_content 'Service Provider: encryption certificate'
      click_link 'Replace certificate'
      expect(current_path).to eql dual_running_path(sp_component.component_type, sp_component.id, sp_component.encryption_certificate_id)
    end

    it 'signing certificate information and navigates to next page' do
      sp_signing_certificate = create(:sp_signing_certificate, component: create(:sp_component, team_id: user.team))
      sp_component = sp_signing_certificate.component
      visit view_certificate_path(sp_component.component_type, sp_component.id, sp_component.signing_certificates[0])
      expect(page).to have_content 'Service Provider: signing certificate'
      click_link 'Add new certificate'
      expect(current_path).to eql before_you_start_path(sp_component.component_type, sp_component.id, sp_component.signing_certificates[0])
    end
  end

  context 'show signing' do
    it 'specific information when certificate is primary and deploying' do
      first_certificate = create(:msa_signing_certificate, component: create(:msa_component, team_id: user.team))
      create(:msa_signing_certificate, component: first_certificate.component)
      visit root_path
      click_link 'Signing certificate (primary)'
      expect(page).to have_content 'GOV.UK Verify is adding your certificate to its configuration'
      expect(page).to_not have_button('Add new certificate')
      expect(page).to have_content(t('user_journey.adding_certificate_to_config'))
      expect(page).to_not have_content(t('user_journey.certificate.stop_using_primary_warning'))
    end

    it 'specific information when certificate is secondary and deploying' do
      first_certificate = create(:msa_signing_certificate, component: create(:msa_component, team_id: user.team))
      create(:msa_signing_certificate, component: first_certificate.component)
      visit root_path
      click_link 'Signing certificate (secondary)'
      expect(page).to have_content 'Wait for an email from GOV.UK Verify confirming your new signing certificate is in use'
      expect(page).to_not have_button('Add new certificate')
      expect(page).to have_content(t('user_journey.wait_for_an_email'))
      expect(page).to_not have_content(t('user_journey.certificate.stop_using_secondary_warning'))
    end

    it 'specific information when certificate is primary and not deploying' do
      first_certificate = create(:msa_signing_certificate, component: create(:msa_component, team_id: user.team))
      create(:msa_signing_certificate, component: first_certificate.component)
      travel_to Time.now + 11.minutes
      visit root_path
      click_link 'Signing certificate (primary)'
      expect(page).to_not have_content 'GOV.UK Verify is adding your certificate to its configuration'
      expect(page).to_not have_button('Add new certificate')
      expect(page).to_not have_content(t('user_journey.adding_certificate_to_config'))
      expect(page).to have_link(t('user_journey.certificate.stop_using_secondary_link'), href: view_certificate_path(first_certificate.component.component_type, first_certificate.component.id, first_certificate.component.enabled_signing_certificates.second))
    end

    it 'specific information when certificate is secondary and not deploying' do
      first_certificate = create(:msa_signing_certificate, component: create(:msa_component, team_id: user.team))
      create(:msa_signing_certificate, component: first_certificate.component)
      travel_to Time.now + 11.minutes
      visit root_path
      click_link 'Signing certificate (secondary)'
      expect(page).to_not have_content 'Wait for an email from GOV.UK Verify confirming your new signing certificate is in use'
      expect(page).to_not have_button('Add new certificate')
      expect(page).to_not have_content(t('user_journey.wait_for_an_email'))
      expect(page).to have_content(t('user_journey.certificate.stop_using_secondary_warning'))
    end
  end
end
