require 'rails_helper'

RSpec.describe 'New SP Component Page', type: :system do
  before(:each) do
    login_gds_user
  end
  let(:entity_id) { 'http://test-entity-id' }
  context 'creation is successful' do
    it 'when required input is specified' do
      component_name = 'test component'
      visit new_sp_component_path
      choose t('sp_components.new.component_type'), allow_label_click: true
      choose 'component_environment_staging'
      fill_in t('sp_components.new.name'), with: component_name
      click_button t('sp_components.new.create_component', type: COMPONENT_TYPE::SP_SHORT)

      expect(current_path).to eql admin_path
    end
  end

  context 'creation fails' do
    it 'when name is not specified' do
      component_name = ''
      visit new_sp_component_path
      choose t('sp_components.new.component_type'), allow_label_click: true
      choose 'component_environment_staging'
      fill_in t('sp_components.new.name'), with: component_name
      click_button t('sp_components.new.create_component', type: COMPONENT_TYPE::SP_SHORT)

      expect(page).to have_content 'Name can\'t be blank'
    end
    it 'error summary links to form fields' do
      visit new_sp_component_path
      click_button t('sp_components.new.create_component', type: COMPONENT_TYPE::SP_SHORT)
      name_blank = find_link("Name can't be blank")
      environment_blank = find_link("Environment can't be blank")
      must_be_component_type = find_link('Component type must be either VSP or SP')

      within 'form#new_component' do
        expect(name_blank[:href]).to eq("##{t('sp_components.new.name')}")
        expect(environment_blank[:href]).to eq("##{t('sp_components.new.environment')}")
        expect(must_be_component_type[:href]).to eq("##{t('sp_components.new.component_type')}")
      end
    end
  end
end
