require 'rails_helper'

RSpec.describe NewSpComponentEvent, type: :model do

  include_examples 'has data attributes', NewSpComponentEvent, %i[name component_type]
  include_examples 'is aggregated', NewSpComponentEvent, name: 'New SP component', component_type: COMPONENT_TYPE::SP
  include_examples 'is a creation event', NewSpComponentEvent, name: 'New component', component_type: COMPONENT_TYPE::SP

  context 'name' do
    it 'must be provided' do
      event = NewSpComponentEvent.create(name: '')
      expect(event).to_not be_valid
      expect(event.errors[:name]).to eql ['can\'t be blank']
    end
  end

  context 'component type' do
    it 'must be provided' do
      event = NewSpComponentEvent.create(component_type: '')
      expect(event).to_not be_valid
      expect(event.errors[:component_type]).to eql ['must be either VSP or SP']
    end
  end
end
