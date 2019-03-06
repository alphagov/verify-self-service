class UploadCertificateEvent < Event
  belongs_to_aggregate :certificate
  data_attributes :value, :usage

  validate :certificate_is_new, on: :create
  validates_inclusion_of :usage, in: ['signing', 'encryption']
  validates_presence_of :value

  def build_certificate
    Certificate.new
  end

  def attributes_to_apply
    {usage: self.usage, value: self.value, created_at: self.created_at}
  end

  def certificate_is_new
    if self.certificate.persisted?
      self.errors.add(:certificate, 'already exists')
    end
  end
end
