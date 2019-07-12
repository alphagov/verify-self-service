require 'rails_helper'

RSpec.describe 'New SP Component Page', type: :system do
  before(:each) do
    login_user
  end
  let(:entity_id) { 'http://test-entity-id' }
  context 'creation is successful' do
    it 'when required input is specified' do
      component_name = 'test component'
      visit new_sp_component_path
      choose 'component_component_type_vspcomponent', allow_label_click: true
      fill_in 'component_name', with: component_name
      click_button 'Create SP component'

      expect(current_path).to eql root_path
    end
  end

  context 'creation fails without name' do
    it 'when name is not specified' do
      component_name = ''
      visit new_sp_component_path
      choose 'component_component_type_vspcomponent', allow_label_click: true
      fill_in 'component_name', with: component_name
      click_button 'Create SP component'

      expect(page).to have_content 'Name can\'t be blank'
    end
  end
end
