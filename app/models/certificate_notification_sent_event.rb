class CertificateNotificationSentEvent < AggregatedEvent
  belongs_to_aggregate :certificate
  data_attributes :notification_sent

  def attributes_to_apply
    { notification_sent: true }
  end
end
