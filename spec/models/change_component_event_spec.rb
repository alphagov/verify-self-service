require 'rails_helper'

RSpec.describe ChangeComponentEvent, type: :model do
  let(:team) { create(:team) }
  let(:msa_component) { create(:new_msa_component_event).msa_component }
  let(:sp_component) { create(:new_sp_component_event).sp_component }
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
      old_team_id = msa_component.team_id

      new_team = create(:team)
      msa_component.team_id = new_team.id

      expect(new_team.id).not_to eq old_team_id
      expect(msa_change_event.team_id).to eq new_team.id
    end
  end

  context 'on SP' do
    it 'must be valid' do
      expect(sp_change_event).to be_valid
      expect(sp_change_event).to be_persisted
      expect(sp_change_event.aggregate_type).to eq COMPONENT_TYPE::SP
    end

    it 'has team id assigned to event metadata' do
      old_team_id = sp_component.team_id

      new_team = create(:team)
      sp_component.team_id = new_team.id

      expect(new_team.id).not_to eq old_team_id
      expect(sp_change_event.team_id).to eq new_team.id
    end
  end
end
