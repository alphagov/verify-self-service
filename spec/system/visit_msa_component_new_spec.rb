require 'rails_helper'

RSpec.describe 'New MSA Component Page', type: :system do
  before(:each) do
    login_gds_user
  end
  let(:entity_id) { 'http://test-entity-id' }
  context 'creation is successful' do
    it 'when required input with entity id for msa is specified' do
      entity = entity_id
      component_name = 'test component'
      visit new_msa_component_path
      fill_in t('msa_components.new.name'), with: component_name
      fill_in t('msa_components.new.entity_id'), with: entity
      choose('component_environment_staging')
      click_button t('msa_components.new.create_component', type: COMPONENT_TYPE::MSA_SHORT)

      expect(current_path).to eql admin_path
    end
  end

  context 'creation fails' do
    it 'when entity id is not specified for msa component' do
      entity = nil
      component_name = 'test component'
      visit new_msa_component_path
      fill_in t('msa_components.new.name'), with: component_name
      fill_in t('msa_components.new.entity_id'), with: entity
      choose('component_environment_staging')
      click_button t('msa_components.new.create_component', type: COMPONENT_TYPE::MSA_SHORT)

      expect(page).to have_content 'Entity id is required for MSA component'
    end

    it 'error summary links to form fields' do
      visit new_msa_component_path
      click_button t('msa_components.new.create_component', type: COMPONENT_TYPE::MSA_SHORT)
      name_blank = find_link("Name can't be blank")
      environment_blank = find_link("Environment can't be blank")
      required_entity_id = find_link('Entity id is required for MSA component')

      within 'form#new_component' do
        expect(name_blank[:href]).to eq("##{t('msa_components.new.name')}")
        expect(environment_blank[:href]).to eq("##{t('msa_components.new.environment')}")
        expect(required_entity_id[:href]).to eq("##{t('msa_components.new.entity_id')}")
      end
    end
  end
end
