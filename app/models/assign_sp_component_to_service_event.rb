class AssignSpComponentToServiceEvent < AggregatedEvent
  belongs_to_aggregate :service
  data_attributes :sp_component_id
  validate :component_is_correct_type?

  def attributes_to_apply
    {
      sp_component_id: sp_component_id,
    }
  end

private

  def component_is_correct_type?
    return if SpComponent.exists?(sp_component_id)

    errors.add(:service, I18n.t('services.errors.wrong_component_type'))
  end
end
