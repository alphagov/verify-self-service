class ToggleEnableEvent < AggregatedEvent
  self.abstract_class = true

  belongs_to_aggregate :certificate
  validates_presence_of :certificate
  validate :certificate_is_signing?
  after_save TriggerMetadataEventCallback.publish

  def attributes_to_apply
    { enabled: enabled }
  end

private

  def certificate_is_signing?
    return if certificate.signing?

    errors.add(:signing_certificate_event, I18n.t("certificates.errors.not_signing"))
  end
end
