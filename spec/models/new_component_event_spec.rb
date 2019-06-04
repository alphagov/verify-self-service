require 'rails_helper'

RSpec.describe NewMsaComponentEvent, type: :model do
  entity_id = 'http://test-entity-id'

  include_examples 'has data attributes', NewMsaComponentEvent, %i[name entity_id]
  include_examples 'is aggregated', NewMsaComponentEvent, name: 'New component', entity_id: entity_id
  include_examples 'is a creation event', NewMsaComponentEvent, name: 'New component', entity_id: entity_id

  context '#component_type' do
    it 'must be one of the known types' do
      event = NewSpComponentEvent.create(name: 'New Component', component_type: 'Unknown')
      expect(event).to_not be_valid
      expect(event.errors[:component_type]).to eql ['is not included in the list']
    end
  end

  context 'name' do
    it 'must be provided' do
      event = NewMsaComponentEvent.create(name: '', entity_id: entity_id)
      expect(event).to_not be_valid
      expect(event.errors[:name]).to eql ['can\'t be blank']
    end
  end
end
