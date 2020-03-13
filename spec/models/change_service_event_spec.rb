require 'rails_helper'

RSpec.describe ChangeServiceEvent, type: :model do
  let(:service) { create(:service) }
  let(:change_service_event) { create(:change_service_event) }
  context 'success' do
    it 'is persisted' do
      expect(change_service_event).to be_valid
      expect(change_service_event).to be_persisted
    end
    it 'changes service entity id' do
      new_entity_id = 'https://changed-entity-id'
      service.assign_attributes(entity_id: new_entity_id)
      change_service_event = create(:change_service_event, service: service)
      expect(change_service_event.data['entity_id']).to eql(new_entity_id)
    end
    it 'changes service name' do
      new_service_name = 'changed service name'
      service.assign_attributes(name: new_service_name)
      change_service_event = create(:change_service_event, service: service)
      expect(change_service_event.data['name']).to eql(new_service_name)
    end
  end
  context '#trigger_publish_event' do
    it 'when entity id is changed on an sp_component' do
      event = create(:assign_sp_component_to_service_event, service: service)
      updated_entity_id = 'https://changed-entity-id1'
      service.assign_attributes(entity_id: updated_entity_id)
      change_service_event = create(:change_service_event, service: service)

      resulting_event = PublishServicesMetadataEvent.where("data->>'event_id' = ?", change_service_event.id).first
      expect(resulting_event).not_to be_nil
      expect(resulting_event.data['services_metadata']['connected_services'][0]['entity_id']).to eq(updated_entity_id)
    end
    it 'when entity id is changed on an msa_component' do
      event = create(:assign_msa_component_to_service_event, service: service)
      updated_entity_id = 'https://changed-entity-id1'
      service.assign_attributes(entity_id: updated_entity_id)
      change_service_event = create(:change_service_event, service: service)

      resulting_event = PublishServicesMetadataEvent.where("data->>'event_id' = ?", change_service_event.id).first
      expect(resulting_event).not_to be_nil
    end
    it 'when a new change service is created without an MSA or SP component it doesnt publish' do
      new_entity_id = 'https://changed-entity-id'
      service.assign_attributes(entity_id: new_entity_id)
      change_service_event = create(:change_service_event, service: service)
      resulting_event = PublishServicesMetadataEvent.where("data->>'event_id' = ?", change_service_event.id).first
      expect(resulting_event).to be_nil
    end
  end
  context 'failure' do
    it 'disallows changing entity_id when change is not unique' do
      [1, 2, 3].each { |n| create(:service, entity_id: "https://not-a-real-entity-id_#{n}") }
      service.assign_attributes(entity_id: "https://not-a-real-entity-id_2")
      expect {
        create(:change_service_event, service: service)
      }.to raise_error.with_message(/Entity has already been taken/)
    end
    it 'disallows changing entity_id to blank' do
      service.assign_attributes(entity_id: '')
      expect {
        create(:change_service_event, service: service)
      }.to raise_error.with_message(/Entity ID is required for the Service/)
    end
    it 'disallows changing service name to blank' do
      service.assign_attributes(name: '')
      expect {
        create(:change_service_event, service: service)
      }.to raise_error.with_message(/Name Enter a name/)
    end
  end
end
