class NewComponentEvent < AggregatedEvent
  belongs_to_aggregate :component
  data_attributes :name, :component_type, :entity_id

  validate :name_is_present
  validates_inclusion_of :component_type, in: %w[VSP MSA SP]
  validate :component_is_new, :msa_has_entity_id, on: :create

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

  def msa_has_entity_id
    if component_type == 'MSA'
      errors.add(:entity_id, 'id is required for MSA component') unless entity_id.present?
      return entity_id.present?
    else
      self.assign_attributes(entity_id: nil)
    end
  end
end
