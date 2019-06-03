require 'rails_helper'
require 'auth_test_helper'

RSpec.describe 'New SP Component Page', type: :system do
  before(:each) { stub_auth }

  let(:component) { create(:sp_component) }
  let(:service_name) { 'Here to serve'}
  let(:service_entity_id) { 'service-entity-id'}

  context 'creation of service is successful' do
    it 'when required input is specified' do
      visit new_sp_component_service_path(component.id)
      fill_in 'service_name', with: service_name
      fill_in 'service_entity_id', with: service_entity_id
      click_button 'Create service'

      expect(current_path).to eql sp_component_path(component.id)
      expect(page).to have_content(service_name)
      expect(page).to have_content(service_entity_id)
    end
  end

  context 'creation fails without entity id' do
    it 'when entity id is not specified' do
      visit new_sp_component_service_path(component.id)
      fill_in 'service_name', with: service_name
      click_button 'Create service'

      expect(page).to have_content 'Entity ID is required'
    end
  end
end
