require 'rails_helper'

RSpec.describe UserAddedToTeamEvent, type: :model do
  let(:user_id) { SecureRandom.uuid }
  let(:team_id) { SecureRandom.uuid }
  let(:team_name) { 'test' }
  let(:event) { UserAddedToTeamEvent.create(data: { user_id: user_id, team_id: team_id, team_name: team_name }) }
  let(:event_with_nil_user_id) {
    UserInfo.current_user = nil
    UserAddedToTeamEvent.create(user_id: nil)
  }

  context '#create' do
    it 'a valid event which contains a user id' do
      expect(event.data['user_id']).to eq(user_id)
      expect(event.data['team_id']).to eq(team_id)
      expect(event.data['team_name']).to eq(team_name)
    end

    it 'a valid event with no user id' do
      expect(event_with_nil_user_id.user_id).to be_nil
    end
  end
end
