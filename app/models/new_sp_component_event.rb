class NewSpComponentEvent < AggregatedEvent
  belongs_to_aggregate :sp_component
  data_attributes :name, :component_type, :environment

  validate :name_is_present
  validate :component_is_new, on: :create
  validates_presence_of :environment, in: Rails.configuration.hub_environments.keys
  validates_inclusion_of :component_type,
                         in: [COMPONENT_TYPE::SP, COMPONENT_TYPE::VSP],
                         message: "must be either VSP or SP"


  def build_sp_component
    SpComponent.new
  end

  def attributes_to_apply
    {
      name: name,
      environment: environment,
      component_type: COMPONENT_TYPE::SP,
      vsp: component_type == COMPONENT_TYPE::VSP,
      created_at: created_at
    }
  end

  def component_is_new
    errors.add(:sp_component, I18n.t('components.errors.already_exists')) if sp_component.persisted?
  end
end
