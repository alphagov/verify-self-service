class NewComponentEvent < AggregatedEvent
  belongs_to_aggregate :component
  data_attributes :name, :component_type, :entity_id

  validate :name_is_present
  validates_inclusion_of :component_type, in: %w[VSP MSA SP]
  validate :persist_entity_id_only_for_msa
  validate :component_is_new, :persist_entity_id_only_for_msa, on: :create

  def build_component
    Component.new
  end

  def attributes_to_apply
    {
      name: name,
      component_type: component_type,
      entity_id: entity_id,
      created_at: created_at
    }
  end

  def component_is_new
    errors.add(:component, 'already exists') if component.persisted?
  end

  private

  def name_is_present
    errors.add(:name, "can't be blank") unless name_present?
  end

  def name_present?
    name.present?
  end

  def persist_entity_id_only_for_msa
    return if component_type == 'MSA' && entity_id.present?

    errors.add(:component, 'Entity id can not be set on VSP component') if entity_id.present?
  end
end
