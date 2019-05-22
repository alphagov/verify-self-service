class ReplaceEncryptionCertificateEvent < AggregatedEvent
  belongs_to_aggregate :component
  data_attributes :encryption_certificate_id
  value_is_present :value
  certificate_is_valid :value
  after_save TriggerMetadataEventCallback.publish

  def attributes_to_apply
    { encryption_certificate_id: encryption_certificate_id }
  end

  def value
    Certificate.find_by_id(encryption_certificate_id)&.value
  end
end
