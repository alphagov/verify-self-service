require 'rails_helper'

RSpec.describe 'New MSA Component Page', type: :system do
  before(:each) do
    login_gds_user
    create_teams
  end

  let(:entity_id) { SecureRandom.alphanumeric }
  let(:team) { create(:new_team_event).team }
  let(:create_teams) { team }
  let(:msa_component) { create(:msa_component, entity_id: 'existing entity_id') }

  context 'creation is successful' do
    it 'when required input with entity id for msa is specified' do
      entity = entity_id
      component_name = 'test component'
      visit new_msa_component_path
      fill_in 'component_name', with: component_name
      fill_in 'component_entity_id', with: entity
      select team.name, from: "component_team_id"
      choose('component_environment_staging')
      click_button 'Create MSA component'

      expect(current_path).to eql admin_path
    end
  end

  context 'creation fails without entity id' do
    it 'when entity id is not specified for msa component' do
      entity = nil
      component_name = 'test component'
      visit new_msa_component_path
      fill_in 'component_name', with: component_name
      fill_in 'component_entity_id', with: entity
      select team.name, from: "component_team_id"
      choose('component_environment_staging')
      click_button 'Create MSA component'

      expect(page).to have_content t('components.errors.missing_entity_id')
    end
  end

  context 'creation fails without unique entity id' do
    it 'when entity id already exists for a msa component' do
      existing_component = msa_component
      entity = 'existing entity_id'
      component_name = 'test component'
      visit new_msa_component_path
      fill_in 'component_name', with: component_name
      fill_in 'component_entity_id', with: entity
      select team.name, from: "component_team_id"
      choose('component_environment_staging')
      click_button 'Create MSA component'

      expect(page).to have_content t('components.errors.invalid_entity_id')
    end
  end

  context 'creation fails without team id' do
    it 'when team id is not specified for msa component' do
      entity = entity_id
      component_name = 'test component'
      visit new_msa_component_path
      fill_in 'component_name', with: component_name
      fill_in 'component_entity_id', with: entity
      choose('component_environment_staging')
      click_button 'Create MSA component'

      expect(page).to have_content t('components.errors.invalid_team')
    end
  end
end
