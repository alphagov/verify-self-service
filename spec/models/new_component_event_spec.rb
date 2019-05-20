require 'rails_helper'
require 'securerandom'
RSpec.describe NewComponentEvent, type: :model do
  entity_id = SecureRandom.hex(10)
  include_examples 'has data attributes', NewComponentEvent, [:name, :component_type, :entity_id]
  include_examples 'is aggregated', NewComponentEvent, {name: 'New component', component_type: 'MSA', entity_id: entity_id }
  include_examples 'is a creation event', NewComponentEvent, {name: 'New component', component_type: 'MSA', entity_id: entity_id }

  context '#component_type' do
    it 'must be one of the known types' do
      event = NewComponentEvent.create(name: 'New Component', component_type: 'Unknown')
      expect(event).to_not be_valid
      expect(event.errors[:component_type]).to eql ['is not included in the list']
    end
  end

  context 'name' do
    it 'must be provided' do
      event = NewComponentEvent.create(name: '', component_type: 'MSA', entity_id: entity_id)
      expect(event).to_not be_valid
      expect(event.errors[:name]).to eql ['can\'t be blank']
    end
  end
end

