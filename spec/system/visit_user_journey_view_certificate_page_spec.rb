require 'rails_helper'

RSpec.describe 'View certificate page', type: :system do
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
      component: vsp_encryption_certificate.component,
      encryption_certificate_id: vsp_encryption_certificate.id
    )
  end

  it 'displays which services the certificate is used by' do
    service = create(:service, sp_component: sp_encryption_certificate.component, name: 'test-service')
    visit view_certificate_path(sp_encryption_certificate.id)
    component_table = page.find("#list-of-services")
    expect(component_table).to have_content 'test-service'
  end

  context 'shows existing msa' do
    it 'encryption certificate information and navigates to next page if not being deployed' do
      expect(CERT_STATUS_UPDATER).to receive(:update_hub_usage_status_for_cert).and_call_original.with(any_args).at_least(:once)
      expect(SCHEDULER).to receive(:mode).and_call_original.at_least(:once)
      create(:replace_encryption_certificate_event, component: msa_encryption_certificate.component, encryption_certificate_id: msa_encryption_certificate.id)
      travel_to Time.now + Rails.configuration.hub_certs_cache_expiry
      visit view_certificate_path(msa_encryption_certificate.id)
      expect(page).to have_content 'Matching Service Adapter: encryption certificate'
      click_link 'Replace certificate'
      expect(current_path).to eql before_you_start_path(msa_encryption_certificate.id)
    end

    it 'encryption certificate information and warning when being deployed' do
      expect(CERT_STATUS_UPDATER).to receive(:update_hub_usage_status_for_cert).with(any_args).and_return(nil).at_least(:once)
      expect(SCHEDULER).to receive(:mode).and_call_original.at_least(:once)
      create(:replace_encryption_certificate_event, component: msa_encryption_certificate.component, encryption_certificate_id: msa_encryption_certificate.id)
      visit view_certificate_path(msa_encryption_certificate.id)
      expect(page).to have_content t('user_journey.replacing_certificate_in_config')
      expect(page).to have_content 'Matching Service Adapter: encryption certificate'
      expect(page).not_to have_content t('user_journey.certificate.replace')
    end

    it 'signing certificate information and navigates to next page' do
      visit view_certificate_path(msa_signing_certificate.id)
      expect(page).to have_content 'Matching Service Adapter: signing certificate'
      click_link 'Add new certificate'
      expect(current_path).to eql before_you_start_path(msa_signing_certificate.id)
    end
  end

  context 'shows existing vsp' do
    it 'encryption certificate information and navigates to next page' do
      create(:assign_sp_component_to_service_event, sp_component_id: vsp_encryption_certificate.component.id)
      travel_to Time.now + Rails.configuration.hub_certs_cache_expiry
      visit view_certificate_path(vsp_encryption_certificate.id)
      expect(page).to have_content 'Verify Service Provider: encryption certificate'
      click_link 'Replace certificate'
      expect(current_path).to eql before_you_start_path(vsp_encryption_certificate.id)
    end

    it 'signing certificate information and navigates to next page' do
      visit view_certificate_path(vsp_signing_certificate.id)
      expect(page).to have_content 'Verify Service Provider: signing certificate'
      click_link 'Add new certificate'
      expect(current_path).to eql before_you_start_path(vsp_signing_certificate.id)
    end
  end

  context 'shows existing sp' do
    it 'encryption certificate information and navigates to next page' do
      create(:assign_sp_component_to_service_event, sp_component_id: sp_encryption_certificate.component.id)
      travel_to Time.now + Rails.configuration.hub_certs_cache_expiry
      visit view_certificate_path(sp_encryption_certificate.id)
      expect(page).to have_content 'Service provider: encryption certificate'
      click_link 'Replace certificate'
      expect(current_path).to eql dual_running_path(sp_encryption_certificate.id)
    end

    it 'signing certificate information and navigates to next page' do
      visit view_certificate_path(sp_signing_certificate.id)
      expect(page).to have_content 'Service provider: signing certificate'
      click_link 'Add new certificate'
      expect(current_path).to eql before_you_start_path(sp_signing_certificate.id)
    end
  end

  context 'show signing' do
    let(:second_signing_certificate) { create(:msa_signing_certificate, component: msa_signing_certificate.component) }
    it 'specific information when certificate is primary and deploying' do
      expect(CERT_STATUS_UPDATER).to receive(:update_hub_usage_status_for_cert).with(any_args).and_return(nil).at_least(:once)
      expect(SCHEDULER).to receive(:mode).and_call_original.at_least(:once)
      create(:assign_msa_component_to_service_event, msa_component_id: msa_signing_certificate.component.id)
      expect(Certificate.find_by_id(msa_signing_certificate)).to be_deploying
      second_signing_certificate
      visit root_path
      click_link 'Signing certificate (primary)'
      expect(page).to have_content 'GOV.UK Verify is adding your certificate to its configuration'
      expect(page).to_not have_button('Add new certificate')
      expect(page).to have_content(t('user_journey.adding_certificate_to_config'))
      expect(page).to_not have_content(t('user_journey.certificate.stop_using_primary_warning'))
    end

    it 'specific information when certificate is secondary and deploying' do
      expect(CERT_STATUS_UPDATER).to receive(:update_hub_usage_status_for_cert).with(any_args).and_return(nil).at_least(:once)
      expect(SCHEDULER).to receive(:mode).and_call_original.at_least(:once)
      create(:assign_msa_component_to_service_event, msa_component_id: second_signing_certificate.component.id)
      expect(Certificate.find_by_id(second_signing_certificate)).to be_deploying
      msa_signing_certificate
      visit root_path
      click_link 'Signing certificate (secondary)'
      expect(page).to have_content 'Wait for an email from GOV.UK Verify confirming your new signing certificate is in use'
      expect(page).to_not have_button('Add new certificate')
      expect(page).to have_content(t('user_journey.wait_for_an_email'))
      expect(page).to_not have_content(t('user_journey.certificate.stop_using_secondary_warning'))
    end

    it 'specific information when certificate is primary and not deploying' do
      second_signing_certificate
      expect(CERT_STATUS_UPDATER).to receive(:update_hub_usage_status_for_cert).and_call_original.at_least(:once)
      expect(SCHEDULER).to receive(:mode).and_call_original.at_least(:once)
      create(:assign_msa_component_to_service_event, msa_component_id: msa_signing_certificate.component.id)
      travel_to Time.now + Rails.configuration.hub_certs_cache_expiry
      expect(Certificate.find_by_id(msa_signing_certificate)).not_to be_deploying

      visit root_path
      click_link 'Signing certificate (primary)'
      expect(page).to_not have_content 'GOV.UK Verify is adding your certificate to its configuration'
      expect(page).to_not have_button('Add new certificate')
      expect(page).to_not have_content(t('user_journey.adding_certificate_to_config'))
      expect(page).to have_link(t('user_journey.certificate.stop_using_secondary_link'), href: view_certificate_path(msa_signing_certificate.component.enabled_signing_certificates.second))
    end

    it 'specific information when certificate is secondary and not deploying' do
      msa_signing_certificate
      expect(CERT_STATUS_UPDATER).to receive(:update_hub_usage_status_for_cert).and_call_original.at_least(:once)
      expect(SCHEDULER).to receive(:mode).and_call_original.at_least(:once)
      create(:assign_msa_component_to_service_event, msa_component_id: second_signing_certificate.component.id)
      travel_to Time.now + Rails.configuration.hub_certs_cache_expiry
      expect(Certificate.find_by_id(second_signing_certificate)).not_to be_deploying
      visit root_path
      click_link 'Signing certificate (secondary)'
      expect(page).to_not have_content 'Wait for an email from GOV.UK Verify confirming your new signing certificate is in use'
      expect(page).to_not have_button('Add new certificate')
      expect(page).to_not have_content(t('user_journey.wait_for_an_email'))
      expect(page).to have_content(t('user_journey.certificate.stop_using_secondary_warning'))
    end
  end

  context 'Stop using certificate' do
    def msa_component_with_primary_and_secondary_certificate
      component = create(:msa_component, team_id: user.team)
      create(:msa_signing_certificate, component: component)
      create(:msa_signing_certificate, component: component)
    end

    before(:example) do
      msa_component_with_primary_and_secondary_certificate
    end

    it 'is secondary' do
      create(:assign_msa_component_to_service_event, msa_component_id: msa_signing_certificate.component.id)
      travel_to Time.now + Rails.configuration.hub_certs_cache_expiry
      visit root_path

      click_link t('user_journey.two_signing_certificate', type: t('user_journey.secondary'))
      click_link t('user_journey.certificate.stop_using')

      expect(page).to have_selector('h1', text: t('components.title'))
      expect(page).not_to have_content(t('user_journey.two_signing_certificate', type: t('user_journey.secondary')))
      expect(page).to have_content(t('user_journey.signing_certificate'))
    end

    it 'is secondary and fails to publish metadata' do
      create(:assign_msa_component_to_service_event, msa_component_id: msa_signing_certificate.component.id)
      travel_to Time.now + Rails.configuration.hub_certs_cache_expiry
      stub_storage_client_service_error

      visit root_path
      click_link t('user_journey.two_signing_certificate', type: t('user_journey.secondary'))
      click_link(t('user_journey.certificate.stop_using'))

      expect(page).to have_selector('h1', text: t('components.title'))
      expect(page).not_to have_content(t('user_journey.two_signing_certificate', type: t('user_journey.secondary')))
      expect(page).to have_content(t('user_journey.signing_certificate'))
      expect(page).to have_content(t('certificates.errors.cannot_publish'))
    end
  end
end
