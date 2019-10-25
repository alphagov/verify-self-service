require 'rails_helper'

RSpec.describe DeleteServiceEvent, type: :model do
  context 'on success' do
    it 'is persisted' do
      delete_service_event = create(:delete_service_event)
      expect(delete_service_event).to be_valid
      expect(delete_service_event).to be_persisted
    end
    it 'when event is called, service is deleted' do
      existing_service = create(:service)
      expect(Service.exists?(existing_service.id)).to be true
      create(:delete_service_event, service: existing_service)
      expect(Service.exists?(existing_service.id)).to be false
    end
  end
end
