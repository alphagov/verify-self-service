require 'rails_helper'

RSpec.describe NewComponentEvent, type: :model do

  include_examples 'has data attributes', NewComponentEvent, [:name, :component_type]
  include_examples 'is aggregated', NewComponentEvent, {name: 'New component', component_type: 'MSA' }
  include_examples 'is a creation event', NewComponentEvent, {name: 'New component', component_type: 'MSA'}

  context '#component_type' do
    it 'must be one of the known types' do
      event = NewComponentEvent.create(name: 'New Component', component_type: 'Unknown')
      expect(event).to_not be_valid
      expect(event.errors[:component_type]).to eql ['is not included in the list']
    end
  end

  context 'name' do
    it 'must be provided' do
      event = NewComponentEvent.create(name:'', component_type: 'MSA')
      expect(event).to_not be_valid
      expect(event.errors[:name]).to eql ['can\'t be blank']
    end
  end
end

