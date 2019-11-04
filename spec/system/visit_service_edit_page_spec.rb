require 'rails_helper'

RSpec.describe "Edit Service Page", type: :system do
  before(:each) do
    login_gds_user
  end

  let(:service) { create(:service) }

  it 'shows existing service to update' do
    visit edit_service_path(service)
    expect(page).to have_field(:service_name, with: service.name)
    expect(page).to have_field(:service_entity_id, with: service.entity_id)
  end
  context 'successful update' do
    it 'allows changing required fields to different values' do
      changed_service_name = SecureRandom.alphanumeric
      changed_service_entity_id = "http://#{SecureRandom.alphanumeric}.com"
      visit edit_service_path(service)
      expect(page).to have_field(:service_name, with: service.name)
      expect(page).to have_field(:service_entity_id, with: service.entity_id)
      fill_in :service_name, with: changed_service_name
      fill_in :service_entity_id, with: changed_service_entity_id
      click_button t('services.update_service')

      expect(page).to have_content(changed_service_name)
        .and have_content(changed_service_entity_id)
    end
  end
  context 'failed update' do
    it 'does not change service name field to blank' do
      changed_service_name = nil
      visit edit_service_path(service)
      expect(page).to have_field(:service_name, with: service.name)
      fill_in :service_name, with: changed_service_name
      click_button t('services.update_service')

      expect(page).to have_content(t'services.service_name')
    end
    it 'does not change service entity_id field to blank' do
      changed_service_entity_id = nil
      visit edit_service_path(service)
      expect(page).to have_field(:service_entity_id, with: service.entity_id)
      fill_in :service_entity_id, with: changed_service_entity_id
      click_button t('services.update_service')

      expect(page).to have_content(t'services.service_id')
    end
  end
end
