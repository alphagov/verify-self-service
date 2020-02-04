class CertificateInUseEvent < AggregatedEvent
  belongs_to_aggregate :certificate
  data_attributes :in_use_at

  def attributes_to_apply
    { in_use_at: Time.now }
  end
end
