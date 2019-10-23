require 'rails_helper'

RSpec.describe AssignSpComponentToServiceEvent, type: :model do

  let(:service) { create(:service) }
  let(:component1) { create(:sp_component) }
  let(:component2) { create(:sp_component) }
  let(:msa_component) { create(:msa_component) }

  it 'must be persisted' do
    event = AssignSpComponentToServiceEvent.create(service: service, sp_component_id: component1.id)
    expect(event).to be_valid
    expect(event).to be_persisted
  end

  it "updates the service's SP component assignment" do
    AssignSpComponentToServiceEvent.create(service: service, sp_component_id: component1.id)
    expect(service.sp_component_id).to eq(component1.id)
    AssignSpComponentToServiceEvent.create(service: service, sp_component_id: component2.id)
    expect(service.sp_component_id).to eq(component2.id)
  end

  it 'does not error if same component is assigned twice' do
    AssignSpComponentToServiceEvent.create(service: service, sp_component_id: component1.id)
    expect(service.sp_component_id).to eq(component1.id)

    event = AssignSpComponentToServiceEvent.create(service: service, sp_component_id: component1.id)
    expect(event).to be_valid
    expect(event).to be_persisted
    expect(service.sp_component_id).to eq(component1.id)
  end

  it 'is not valid if component id is for an MSA component' do
    event = AssignSpComponentToServiceEvent.create(service: service, sp_component_id: msa_component.id)
    expect(event).not_to be_valid
    expect(event).not_to be_persisted
  end
end
