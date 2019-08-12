require 'rails_helper'

RSpec.describe NewSpComponentEvent, type: :model do

  include_examples 'has data attributes', NewSpComponentEvent, %i[name component_type], environment: 'staging'
  include_examples 'is aggregated', NewSpComponentEvent, name: 'New SP component', component_type: COMPONENT_TYPE::SP, environment: 'staging'
  include_examples 'is a creation event', NewSpComponentEvent, name: 'New component', component_type: COMPONENT_TYPE::SP, environment: 'staging'

  context 'name' do
    it 'must be provided' do
      event = build(:new_sp_component_event, name: '', environment: 'staging')
      expect(event).to_not be_valid
      expect(event.errors[:name]).to eql ['can\'t be blank']
    end
  end

  context 'environment' do
    it 'must be provided' do
      event = build(:new_sp_component_event, name: 'New component', environment: '')
      expect(event).to_not be_valid
      expect(event.errors[:environment]).to eql ['can\'t be blank']
    end
  end

  context 'component type' do
    it 'must be provided' do
      event = build(:new_sp_component_event, component_type: '', environment: 'staging')
      expect(event).to_not be_valid
      expect(event.errors[:component_type]).to eql ['must be either VSP or SP']
    end
  end

  context 'user_id' do
    it 'must exist' do
      user_id = SecureRandom.uuid
      user = User.new
      user.user_id = user_id
      RequestStore.store[:user] = user
      event = create(:new_sp_component_event)

      expect(event.user_id).to eql user_id
    end
  end
end
