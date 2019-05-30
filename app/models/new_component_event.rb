class NewComponentEvent < AggregatedEvent
  belongs_to_aggregate :component
  data_attributes :name, :component_type, :entity_id

  validate :name_is_present
  validates_inclusion_of :component_type, in: %w[VSP MSA SP]
  validate :component_is_new, on: :create

  def build_component
    Component.new
  end

  def attributes_to_apply
    {
      name: name,
      component_type: component_type,
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
end
