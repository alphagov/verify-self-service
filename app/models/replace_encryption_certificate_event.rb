class ReplaceEncryptionCertificateEvent < AggregatedEvent
  belongs_to_aggregate :component
  data_attributes :encryption_certificate_id
  
  def attributes_to_apply
    { encryption_certificate_id: encryption_certificate_id }
  end
end