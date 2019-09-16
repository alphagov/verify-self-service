require 'rails_helper'

RSpec.describe NewSpComponentEvent, type: :model do
  include_examples 'components have data attributes', :new_sp_component_event, {
    name: 'It was the day my grandmother exploded',
    component_type: COMPONENT_TYPE::SP,
    environment: 'staging'
  }
  include_examples 'components are aggregated', :new_sp_component_event
  include_examples 'component creation event', :new_sp_component_event

  context 'name' do
    it 'must be provided' do
      event = build(:new_sp_component_event, name: '')
      expect(event).to_not be_valid
      expect(event.errors[:name]).to eql [t('events.errors.missing_name')]
    end
  end

  context 'environment' do
    it 'must be provided' do
      event = build(:new_sp_component_event, name: 'New component', environment: '')
      expect(event).to_not be_valid
      expect(event.errors[:environment]).to eql [t('components.errors.invalid_environment')]
    end
  end

  context 'component type' do
    it 'must be provided' do
      event = build(:new_sp_component_event, component_type: '')
      expect(event).to_not be_valid
      expect(event.errors[:component_type]).to eql [t('components.errors.invalid_type')]
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
