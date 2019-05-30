require 'rails_helper'

RSpec.describe Service, type: :model do
  context 'adding components to a service' do
    it 'should create a new service correctly' do
      service = create(:service, component: create(:component))

      expect(service).to be_valid
      expect(service).to be_persisted
    end
  end
end
