require 'rails_helper'

RSpec.describe 'New Component Page', type: :system do

  context 'creation is successful' do
    it 'when required input is specified' do
      component_name = 'test component'
      visit new_component_path
      choose 'component_component_type_vsp', allow_label_click: true
      fill_in 'component_name', with: component_name
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
  end
end
