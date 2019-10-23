require 'rails_helper'

RSpec.describe DeleteComponentEvent, type: :model do
  include CognitoSupport

  context 'on successful component deletion event' do
    it 'event is persisted' do
      delete_component_event = create(:delete_component_event)
      expect(delete_component_event).to be_valid
      expect(delete_component_event).to be_persisted
    end
  end
end
