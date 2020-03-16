class ChangeServiceEvent < AggregatedEvent
  belongs_to_aggregate :service
  data_attributes :attributes_changed
  validate :validate_changes
  after_save TriggerMetadataEventCallback.publish

  def attributes_to_apply
    self.data = attributes_changed
    attributes_changed
  end

  def attributes_changed
    service.changes.transform_values { |changes| changes[1] }
  end

  def attribute_changes
    service.changes
  end

private

  def validate_changes
    return if attribute_changes.nil?

    attribute_changes.each do |attribute, value|
      case attribute
      when "name"
        errors.add(:name, I18n.t('events.errors.missing_name')) unless value[1].present?
      when "entity_id"
        errors.add(:entity_id, I18n.t('services.errors.missing_entity_id')) unless value[1].present?
      else
        raise NotImplementedError.new("Attribute #{attribute} is unexpected or missing validation")
      end
    end
  end
end
