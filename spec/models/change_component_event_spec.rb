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

  # Common fields tested within these shared examples
  include_examples 'change component event', %w[msa sp]

  context 'MSA specific fields' do
    it 'errors when entity ID is not present' do
      msa_component.entity_id = ''

      expect(msa_change_event).to_not be_valid
      expect(msa_change_event.errors[:entity_id]).to eql [t('components.errors.missing_entity_id')]
    end
  end

  context 'SP specific fields' do
    it 'errors when component_type is not present' do
      sp_component.component_type = ''

      expect(sp_change_event).to_not be_valid
      expect(sp_change_event.errors[:component_type]).to eql [t('components.errors.invalid_type')]
    end
  end
end
