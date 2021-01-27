require 'rails_helper'

RSpec.describe 'New Service Page', type: :system do
  before(:each) do
    login_gds_user
  end

  let(:entity_id) { 'http://test-entity-id' }

  context 'creation is successful' do
    it 'when required input is specified' do
      service_name = 'test component'
      entity_id = 'http://www.gov.uk'
      visit new_service_path
      fill_in 'service_name', with: service_name
      fill_in 'service_entity_id', with: entity_id
      click_button 'Create service'

      expect(current_path).to eql admin_path
    end

    it 'when entity id has only leading and trailing spaces' do
      service_name = 'test component'
      entity_id = ' http://test-entity-id '
      visit new_service_path
      fill_in 'service_name', with: service_name
      fill_in 'service_entity_id', with: entity_id
      click_button 'Create service'

      expect(current_path).to eql admin_path
    end
  end

  context 'creation fails without name' do
    it 'when name is not specified' do
      service_name = ''
      entity_id = 'http://www.gov.uk'
      visit new_service_path
      fill_in 'service_name', with: service_name
      fill_in 'service_entity_id', with: entity_id
      click_button 'Create service'

      expect(page).to have_content I18n.t('events.errors.missing_name')
    end
  end

  context 'creation fails on entity id' do
    it 'when entity id is not specified' do
      service_name = 'test component'
      entity_id = ''
      visit new_service_path
      fill_in 'service_name', with: service_name
      fill_in 'service_entity_id', with: entity_id
      click_button 'Create service'

      expect(page).to have_content I18n.t('services.errors.missing_entity_id')
    end

    it 'when entity id has spaces between words' do
      service_name = 'test component'
      entity_id = ' http://test entity id '
      visit new_service_path
      fill_in 'service_name', with: service_name
      fill_in 'service_entity_id', with: entity_id
      click_button 'Create service'

      expect(page).to have_content I18n.t('services.errors.invalid_entity_id_format')
    end
  end
end
