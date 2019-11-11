class AssignMsaComponentToServiceEvent < AggregatedEvent
  belongs_to_aggregate :service
  data_attributes :msa_component_id, :name
  validate :component_is_correct_type?
  after_save TriggerMetadataEventCallback.publish

  def attributes_to_apply
    {
      msa_component_id: msa_component_id,
    }
  end

private

  def component_is_correct_type?
    return if MsaComponent.exists?(msa_component_id)

    errors.add(:service, I18n.t('services.errors.wrong_component_type'))
  end
end
