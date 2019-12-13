class ChangeComponentEvent < AggregatedEvent
  belongs_to_aggregate :component

  data_attributes :attributes_changed
  validate :validate_changes

  def attributes_to_apply
    self.data = attributes_changed
    attributes_changed
  end

  def attributes_changed
    component.changes.transform_values { |changes| changes[1] }
  end

  def attribute_changes
    component.changes
  end

private

  def validate_changes
    return if attribute_changes.nil?

    attribute_changes.each do |attribute, value|
      case attribute
      when "name"
        errors.add(:name, I18n.t('events.errors.missing_name')) unless value[1].present?
      when "vsp"
        errors.add(:component_type, I18n.t('components.errors.invalid_type')) unless [true, false].include?(value[1])
      when "team_id"
        errors.add(:team_id, I18n.t('components.errors.invalid_team')) unless value[1].present?
      when "environment"
        errors.add(:environment, I18n.t('components.errors.invalid_environment')) unless environment_present_and_valid?(value[1])
      when "component_type"
        errors.add(:component_type, I18n.t('components.errors.invalid_type')) unless component_type_present_and_valid?(value[1])
      when "entity_id"
        errors.add(:entity_id, I18n.t('components.errors.missing_entity_id')) unless value[1].present?
      else
        raise NotImplementedError.new("Attribute #{attribute} is unexpected or missing validation")
      end
    end
  end

  def component_type_present_and_valid?(component_type)
    [COMPONENT_TYPE::SP, COMPONENT_TYPE::VSP].include?(component_type)
  end

  def environment_present_and_valid?(environment)
    Rails.configuration.hub_environments_legacy.keys.include?(environment)
  end
end
