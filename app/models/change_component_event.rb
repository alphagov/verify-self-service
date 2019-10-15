class ChangeComponentEvent < AggregatedEvent
  belongs_to_aggregate :component

  data_attributes :name, :component_type, :team_id, :environment, :entity_id
  validate :validate_changes

  def attributes_to_apply
    self.data = attributes_changed
    attributes_changed
  end

  def attributes_changed
    component.attributes.slice(component.changed.join(', '))
  end

  def attribute_changes
    component.changes
  end

  def validate_changes
    attribute_changes.each do |attribute, value|
      case attribute
      when "name"
        errors.add(:name, I18n.t('events.errors.missing_name')) unless value[1].present?
      when "team_id"
        errors.add(:team_id, I18n.t('components.errors.invalid_team')) unless value[1].present?
      when "environment"
        errors.add(:environment, I18n.t('components.errors.invalid_environment')) unless environment_present_and_valid?(value[1])
      when "component_type"
        errors.add(:component_type, I18n.t('components.errors.invalid_type')) unless component_type_present_and_valid?(value[1])
      when "entity_id"
        errors.add(:entity_id, I18n.t('components.errors.missing_entity_id')) unless value[1].present?
      end
    end
  end

  def component_type_present_and_valid?(component_type)
    [COMPONENT_TYPE::SP, COMPONENT_TYPE::VSP].include?(component_type)
  end

  def environment_present_and_valid?(environment)
    Rails.configuration.hub_environments.keys.include?(environment)
  end
end
