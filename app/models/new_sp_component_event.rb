class NewSpComponentEvent < AggregatedEvent
  belongs_to_aggregate :sp_component
  data_attributes :name, :component_type

  validate :name_is_present
  validates_inclusion_of :component_type, in: %w[VSP SP]
  validate :component_is_new, on: :create

  def build_sp_component
    SpComponent.new
  end

  def attributes_to_apply
    {
      name: name,
      component_type: component_type,
      created_at: created_at
    }
  end

  def component_is_new
    errors.add(:sp_component, 'already exists') if sp_component.persisted?
  end
end
