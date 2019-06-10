class NewSpComponentEvent < AggregatedEvent
  belongs_to_aggregate :sp_component
  data_attributes :name, :component_type

  validate :name_is_present
  validate :component_is_new, on: :create
  validates_inclusion_of :component_type,
                         in: [CONSTANTS::SP, CONSTANTS::VSP],
                         message: "must be either VSP or SP"


  def build_sp_component
    SpComponent.new
  end

  def attributes_to_apply
    {
      name: name,
      component_type: CONSTANTS::SP,
      vsp: component_type == CONSTANTS::VSP,
      created_at: created_at
    }
  end

  def component_is_new
    errors.add(:sp_component, 'already exists') if sp_component.persisted?
  end
end
