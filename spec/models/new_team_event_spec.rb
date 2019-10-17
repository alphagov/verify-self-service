require 'rails_helper'

RSpec.describe NewTeamEvent, type: :model do
  include CognitoSupport

  context 'on successful creation' do
    it 'is valid and persisted' do
      stub_cognito_response(method: :create_group)
      team_event = create(:new_team_event, name: 'The O Father')
      expect(team_event).to be_valid
      expect(team_event).to be_persisted
    end

    it 'has team event' do
      stub_cognito_response(method: :create_group)
      team_event = create(:new_team_event, name: 'J Snoop')
      expect(team_event).to eq NewTeamEvent.last
    end
  end

  context 'creation fails' do
    it 'when name is not given' do
      event = NewTeamEvent.create
      error_message_on_name = event.errors[:name].first
      expect(error_message_on_name).to eq t('team.errors.blank_name')
    end

    it 'when team already exists with a different name but same resulting alias' do
      existing_team = create(:team, name: 'test team name', team_alias: 'testteamname')
      new_team_event = NewTeamEvent.create(name: 'testteamname')
      expect(new_team_event.team.valid?).to be false
      expect(new_team_event).not_to be_persisted
    end
  end
end
