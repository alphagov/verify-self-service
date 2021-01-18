class NewMsaComponentEvent < AggregatedEvent
  belongs_to_aggregate :msa_component
  data_attributes :name, :entity_id, :team_id, :environment
  validate :msa_has_entity_id
  validate :component_is_new, on: :create
  validate :not_an_existing_msa_entity_id, on: :create
  validates_presence_of :name, message: I18n.t('events.errors.missing_name')
  validates_presence_of :team_id, message: I18n.t('components.errors.invalid_team')
  validates_presence_of :environment,
                        in: Rails.configuration.hub_environments.keys,
                        message: I18n.t('components.errors.invalid_environment')

  def build_msa_component
    MsaComponent.new
  end

  def attributes_to_apply
    {
      name: name,
      component_type: COMPONENT_TYPE::MSA,
      team_id: team_id,
      environment: environment,
      entity_id: entity_id,
      created_at: created_at,
    }
  end

  def component_is_new
    errors.add(:msa_component, I18n.t('components.errors.already_exists')) if msa_component.persisted?
  end

private

  def not_an_existing_msa_entity_id
    errors.add(:entity_id, I18n.t('components.errors.invalid_entity_id')) if MsaComponent.exists? entity_id: entity_id
  end

  def msa_has_entity_id
    errors.add(:entity_id, I18n.t('components.errors.missing_entity_id')) unless entity_id.present?
  end
end
