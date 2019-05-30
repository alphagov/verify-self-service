class NewMsaComponentEvent < NewComponentEvent
  validate :msa_has_entity_id

  def build_msa_component
    MsaComponent.new
  end

  def attributes_to_apply
    {
      name: name,
      component_type: component_type,
      entity_id: entity_id,
      created_at: created_at
    }
  end

private

  def msa_has_entity_id
    errors.add(:entity_id, 'id is required for MSA component') unless entity_id.present?
    entity_id.present?
  end
end
