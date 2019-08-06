require 'rails_helper'

RSpec.describe ChangeComponentEvent, type: :model do
  let(:msa_component) { create(:new_msa_component_event).msa_component }
  let(:sp_component) { create(:new_sp_component_event).sp_component }
  let(:team_id) { 1 }
  let(:msa_change_event) do
    ChangeComponentEvent.create(component: msa_component)
  end
  let(:sp_change_event) do
    ChangeComponentEvent.create(component: sp_component)
  end

  context 'on MSA' do
    it 'must be valid' do
      expect(msa_change_event).to be_valid
      expect(msa_change_event).to be_persisted
      expect(msa_change_event.aggregate_type).to eq COMPONENT_TYPE::MSA
    end

    it 'has team id assigned to event metadata' do
      expect(msa_component.team_id).to be_nil
      msa_component.team_id = team_id

      expect(msa_change_event.team_id).to eq team_id
    end
  end
 
  context 'on SP' do
    it 'must be valid' do
      expect(sp_change_event).to be_valid
      expect(sp_change_event).to be_persisted
      expect(sp_change_event.aggregate_type).to eq COMPONENT_TYPE::SP
    end

    it 'has team id assigned to event metadata' do
      expect(sp_component.team_id).to be_nil
      sp_component.team_id = team_id

      expect(sp_change_event.team_id).to eq team_id
    end
  end

end
