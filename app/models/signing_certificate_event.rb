class SigningCertificateEvent < AggregatedEvent
  self.abstract_class = true
  belongs_to_aggregate :certificate
  validates_presence_of :certificate
  validate :certificate_is_signing?

  def attributes_to_apply
    { enabled: enabled }
  end

  def certificate_is_signing?
    return if certificate.usage == 'signing'

    errors.add(:signing_certificate_event, 'signing certificate required')
  end
end