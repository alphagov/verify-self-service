require 'rails_helper'

RSpec.describe 'New Component Page', type: :system do
  let(:entity_id) { 'http://test-entity-id' }
  context 'creation is successful' do
    it 'when required input is specified' do
      component_name = 'test component'
      visit new_component_path
      choose 'component_component_type_vsp', allow_label_click: true
      fill_in 'component_name', with: component_name
      click_button 'Create component'

      expect(current_path).to eql components_path
    end

    it 'when required input with entity id for msa is specified' do
      entity = entity_id
      component_name = 'test component'
      visit new_component_path
      choose 'component_component_type_msa', allow_label_click: true
      fill_in 'component_name', with: component_name
      fill_in 'component_entity_id', with: entity
      click_button 'Create component'

      expect(current_path).to eql components_path
    end

    it 'when required input without entity id for vsp is not specified' do
      entity = nil
      component_name = 'test component'
      visit new_component_path
      choose 'component_component_type_vsp', allow_label_click: true
      fill_in 'component_name', with: component_name
      fill_in 'component_entity_id', with: entity
      click_button 'Create component'

      expect(current_path).to eql components_path
    end
  end

  context 'creation fails' do
    it 'when name is not specified' do
      component_name = ''
      visit new_component_path
      choose 'component_component_type_vsp', allow_label_click: true
      fill_in 'component_name', with: component_name
      click_button 'Create component'

      expect(page).to have_content 'Name can\'t be blank'
    end

    it 'when component type is not specified' do
      component_name = 'test component'
      visit new_component_path
      fill_in 'component_name', with: component_name
      click_button 'Create component'

      expect(page).to have_content 'Component type is not included in the list'
    end

    it 'when entity id is not specified for msa component' do
      entity = nil
      component_name = 'test component'
      visit new_component_path
      choose 'component_component_type_msa', allow_label_click: true
      fill_in 'component_name', with: component_name
      fill_in 'component_entity_id', with: entity
      click_button 'Create component'

      expect(page).to have_content 'Entity id is required for MSA component'
    end
  end
end
