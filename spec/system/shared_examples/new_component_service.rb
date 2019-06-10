require 'auth_test_helper'
RSpec.shared_examples "new component page" do |component_name|
  before(:each) { stub_auth }

  let(:service_name) { 'Here to serve'}
  let(:service_entity_id) { 'service-entity-id'}
  let(:component) { create(component_name) }

  context 'creation of service is successful' do
    it 'when required input is specified' do
      visit polymorphic_url([:new, component, :service], component: component)
      fill_in 'service_name', with: service_name
      fill_in 'service_entity_id', with: service_entity_id
      click_button 'Create service'

      expect(current_url).to eql polymorphic_url(component)
      expect(page).to have_content(service_name)
      expect(page).to have_content(service_entity_id)
    end
  end

  context 'creation fails' do
    it 'when entity id is not specified' do
      visit polymorphic_url([:new, component, :service], component: component)
      fill_in 'service_name', with: service_name
      click_button 'Create service'

      expect(page).to have_content 'Entity ID is required'
    end

    it 'when name is not specified' do
      visit polymorphic_url([:new, component, :service], component: component)
      fill_in 'service_entity_id', with: service_entity_id
      click_button 'Create service'

      expect(page).to have_content 'Name can\'t be blank'
    end
  end
end
