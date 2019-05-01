class SigningCertificateEvent < AggregatedEvent
  self.abstract_class = true
  data_attributes :usage, :value, :component_id, :id, :enabled, :created_at
  belongs_to_aggregate :certificate
  validates_presence_of :certificate
  validate :certificate_is_signing?

  def attributes_to_apply
    assign_attributes(event_metadata_hash)
    { enabled: enabled }
  end

  private

  def event_metadata_hash
    certificate.attributes.slice(
      'usage', 'value', 'component_id', 'id', 'enabled', 'created_at'
    )
  end

  def certificate_is_signing?
    return if certificate.usage == 'signing'

    errors.add(:signing_certificate_event, 'signing certificate required')
  end
end
