class NewMsaComponentEvent < AggregatedEvent
  belongs_to_aggregate :msa_component
  data_attributes :name, :entity_id
  validate :msa_has_entity_id
  validate :component_is_new, on: :create
  validate :name_is_present

  def build_msa_component
    MsaComponent.new
  end

  def attributes_to_apply
    {
      name: name,
      component_type: CONSTANTS::MSA,
      entity_id: entity_id,
      created_at: created_at
    }
  end

  def component_is_new
    errors.add(:msa_component, 'already exists') if msa_component.persisted?
  end

private

  def msa_has_entity_id
    errors.add(:entity_id, 'id is required for MSA component') unless entity_id.present?
  end
end
