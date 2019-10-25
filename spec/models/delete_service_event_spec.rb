require 'rails_helper'

RSpec.describe DeleteServiceEvent, type: :model do
  context 'on success' do
    it 'event is persisted' do
      delete_service_event = create(:delete_service_event)
      expect(delete_service_event).to be_valid
      expect(delete_service_event).to be_persisted
    end
    it 'has a delete service event' do
      delete_service_event = create(:delete_service_event)
      expect(delete_service_event).to eq DeleteServiceEvent.last
    end
  end
end
