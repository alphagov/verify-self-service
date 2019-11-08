require 'rails_helper'

RSpec.describe AssignSpComponentToServiceEvent, type: :model do

  let(:service) { create(:service) }
  let(:component_1) { create(:sp_component) }
  let(:component_2) { create(:sp_component) }
  let(:msa_component) { create(:msa_component) }

  it 'must be persisted' do
    event = create(:assign_sp_component_to_service_event, service: service, sp_component_id: component_1.id)
    expect(event).to be_valid
    expect(event).to be_persisted
  end

  it "updates the service's SP component assignment" do
    create(:assign_sp_component_to_service_event, service: service, sp_component_id: component_1.id)
    expect(service.sp_component_id).to eq(component_1.id)
    create(:assign_sp_component_to_service_event,service: service, sp_component_id: component_2.id)
    expect(service.sp_component_id).to eq(component_2.id)
  end

  it 'does not error if same component is assigned twice' do
    create(:assign_sp_component_to_service_event, service: service, sp_component_id: component_1.id)
    expect(service.sp_component_id).to eq(component_1.id)

    event = create(:assign_sp_component_to_service_event, service: service, sp_component_id: component_1.id)
    expect(event).to be_valid
    expect(event).to be_persisted
    expect(service.sp_component_id).to eq(component_1.id)
  end

  it 'is not valid if component id is for an MSA component' do
    event = AssignSpComponentToServiceEvent.create(service: service, sp_component_id: msa_component.id)
    expect(event).not_to be_valid
    expect(event).not_to be_persisted
    expect(event.errors.full_messages.first).to eq('Service Wrong component type')
  end

  context '#trigger_publish_event' do
    it 'when component is assigned to service is enabled' do
      event = create(:assign_sp_component_to_service_event, service: service, sp_component_id: component_1.id)

      resulting_event = PublishServicesMetadataEvent.all.select do |evt|
        evt.event_id == event.id
      end.first

      expect(resulting_event).to be_present
    end
  end
end
