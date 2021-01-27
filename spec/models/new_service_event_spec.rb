require 'rails_helper'

RSpec.describe NewServiceEvent, type: :model do
  
  context 'name' do
    it 'must be provided' do
      event = build(:new_service_event, name: '')
      expect(event).to_not be_valid
      expect(event.errors[:name]).to eql [t('events.errors.missing_name')]
    end
  end

  context 'entity_id' do
    it 'must be provided' do
      event = build(:new_service_event, entity_id: '')
      expect(event).to_not be_valid
      expect(event.errors[:entity_id]).to eql [t('services.errors.missing_entity_id')]
    end

    it 'is valid when there is only leading and trailing whitespaces' do
      event = build(:new_service_event, entity_id: ' https://test-entity-id ')
      expect(event).to be_valid
      expect(event.errors[:entity_id]).to eql []
      expect(event.entity_id).to eql "https://test-entity-id"
    end

     it 'must not contain spaces between words' do
      event = build(:new_service_event, entity_id: 'https://test entity id')
      expect(event).to_not be_valid
      expect(event.errors[:entity_id]).to eql [t('services.errors.invalid_entity_id_format')]
    end
  end
end