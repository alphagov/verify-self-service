class NewSpComponentEvent < AggregatedEvent
  belongs_to_aggregate :sp_component
  data_attributes :name, :component_type, :team_id, :environment

  validate :component_is_new, on: :create
  validates_presence_of :name, message: I18n.t('events.errors.missing_name')
  validates_presence_of :team_id, message: I18n.t('components.errors.invalid_team')
  validates_presence_of :environment,
                        in: Rails.configuration.hub_environments.keys,
                        message: I18n.t('components.errors.invalid_environment')
  validates_inclusion_of :component_type,
                         in: [COMPONENT_TYPE::SP, COMPONENT_TYPE::VSP],
                         message: I18n.t('components.errors.invalid_type')


  def build_sp_component
    SpComponent.new
  end

  def attributes_to_apply
    {
      name: name,
      team_id: team_id,
      environment: environment,
      component_type: COMPONENT_TYPE::SP,
      vsp: component_type == COMPONENT_TYPE::VSP,
      created_at: created_at,
    }
  end

  def component_is_new
    errors.add(:sp_component, I18n.t('components.errors.already_exists')) if sp_component.persisted?
  end
end
