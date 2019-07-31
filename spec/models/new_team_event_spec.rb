require 'rails_helper'

RSpec.describe NewTeamEvent, type: :model do
  context 'on successful creation' do
    it 'is valid and persisted' do
      team_event = create(:new_team_event)
      expect(team_event).to be_valid
      expect(team_event).to be_persisted
    end

    it 'has team event' do
      team_event = create(:new_team_event)
      expect(team_event).to eq NewTeamEvent.last
    end
  end

  context 'creation fails' do
    it 'when name is not given' do
      event = NewTeamEvent.create
      error_message_on_name = event.errors.full_messages_for(:name)
      expect(error_message_on_name).to eq ["Name can't be blank"]
    end
  end
end
