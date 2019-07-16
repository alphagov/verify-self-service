require 'rails_helper'

RSpec.describe 'New MSA Component Page', type: :system do
  before(:each) do
    login_user
  end
  let(:entity_id) { 'http://test-entity-id' }
  context 'creation is successful' do
    it 'when required input with entity id for msa is specified' do
      entity = entity_id
      component_name = 'test component'
      visit new_msa_component_path
      fill_in 'component_name', with: component_name
      fill_in 'component_entity_id', with: entity
      click_button 'Create MSA component'

      expect(current_path).to eql root_path
    end
  end

  context 'creation fails without entity id' do
    it 'when entity id is not specified for msa component' do
      entity = nil
      component_name = 'test component'
      visit new_msa_component_path
      fill_in 'component_name', with: component_name
      fill_in 'component_entity_id', with: entity
      click_button 'Create MSA component'

      expect(page).to have_content 'Entity id is required for MSA component'
    end
  end
end
