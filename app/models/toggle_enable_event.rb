class ToggleEnableEvent < AggregatedEvent
  self.abstract_class = true

  belongs_to_aggregate :certificate
  validates_presence_of :certificate
  validate :certificate_is_signing?, :not_only_certificate?
  after_save TriggerMetadataEventCallback.publish

  def attributes_to_apply
    { enabled: enabled }
  end

private

  def certificate_is_signing?
    return if certificate.signing?

    errors.add(:certificate, I18n.t('certificates.errors.not_signing'))
  end

  def not_only_certificate?
    return if certificate.encryption?
    return if enabled
    return if certificate.component.enabled_signing_certificates.length == 2

    errors.add(:certificate, I18n.t('certificates.errors.cannot_disable'))
  end
end
