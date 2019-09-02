require 'rails_helper'

RSpec.describe 'Edit SP Component Page', type: :system do
  before(:each) do
    login_gds_user
  end
  let(:sp_component) { create(:sp_component) }
  let(:team) { create(:new_team_event).team }
  let(:create_teams) { team }

  context 'when team option is selected' do
    it 'successfully associates team id with component' do
      create_teams
      visit edit_sp_component_path(sp_component)
      select(team.name, from: 'component[team_id]')
      click_button t('team.associate_team')
      result = SpComponent.find_by_id(sp_component.id)
      expect(current_path).to eq sp_components_path
      expect(result.team_id).to eq team.id
    end
  end

  context 'when team option is unselected' do
    it 'successfully deassociates team id from component' do
      create_teams
      visit edit_sp_component_path(sp_component)
      select(team.name, from: 'component[team_id]')
      select('Select', from: 'component[team_id]')
      click_button t('team.associate_team')
      result = SpComponent.find_by_id(sp_component.id)
      expect(current_path).to eq sp_components_path
      expect(result.team_id).to be_nil
    end
  end
end
