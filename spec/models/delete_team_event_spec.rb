require 'rails_helper'

RSpec.describe DeleteTeamEvent, type: :model do
  include CognitoSupport

  context 'on successful team deletion' do
    it 'team is deleted and event persisted' do
      stub_cognito_response(method: :delete_group)
      stub_cognito_response(method: :list_users_in_group, payload: [])
      delete_team_event = create(:delete_team_event)
      expect(delete_team_event).to be_valid
      expect(delete_team_event).to be_persisted
      expect(Team.exists?(delete_team_event.team.id)).to be false
    end

    it 'has delete team event' do
      stub_cognito_response(method: :delete_group)
      stub_cognito_response(method: :list_users_in_group, payload: [])
      delete_team_event = create(:delete_team_event)
      expect(delete_team_event).to eq DeleteTeamEvent.last
    end

    it 'team is delete even if Cognito group does not exist or has already been deleted' do
      stub_cognito_response(method: :delete_group, payload: 'ResourceNotFoundException')
      stub_cognito_response(method: :list_users_in_group, payload: [])
      delete_team_event = create(:delete_team_event)
      expect(delete_team_event).to be_valid
      expect(delete_team_event).to be_persisted
      expect(Team.exists?(delete_team_event.team.id)).to be false
    end
  end

  context 'deletion fails' do
    it 'when the team has members' do
      stub_cognito_response(method: :delete_group)
      stub_cognito_response(method: :list_users_in_group, payload: { users: [ { username: 'user'} ] })
      existing_team = create(:team)
      expect{ create(:delete_team_event, team: existing_team)}.to raise_error(ActiveRecord::RecordInvalid)
      expect(Team.exists?(existing_team.id)).to be true
    end
    it 'when cognito call fails' do
      stub_cognito_response(method: :delete_group, payload: 'ServiceError')
      stub_cognito_response(method: :list_users_in_group, payload: [])
      existing_team = create(:team)
      expect{ create(:delete_team_event, team: existing_team)}.to raise_error(ActiveRecord::RecordInvalid)
      expect(Team.exists?(existing_team.id)).to be true
    end
  end
end
