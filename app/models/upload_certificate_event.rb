class UploadCertificateEvent < Event
  belongs_to_aggregate :certificate
  data_attributes :value, :usage

  validate :certificate_is_valid,
           :certificate_is_new, on: :create, if: :value_present?

  validates_inclusion_of :usage, in: ['signing', 'encryption']
  validates_presence_of :value

  def build_certificate
    Certificate.new
  end

  def attributes_to_apply
    {usage: self.usage, value: self.value, created_at: self.created_at}
  end

  private

  def value_present?
    self.value.present?
  end

  def certificate_is_new
    if self.certificate.persisted?
      self.errors.add(:certificate, 'already exists')
    end
  end

  def certificate_is_valid
    x509cert = valid_certificate value
    unless x509cert.nil?
      certificate_has_appropriate_not_after x509cert
      certificate_key_is_supported x509cert
      self.value = Base64.strict_encode64(x509cert.to_der)
    end
  end

  def certificate_has_appropriate_not_after(x509cert)
    if x509cert.not_after < Time.now
      self.errors.add(:certificate, 'has expired')
    elsif x509cert.not_after < Time.now + 30.days
      self.errors.add(:certificate, 'expires too soon')
    elsif x509cert.not_after > Time.now + 1.year
      self.errors.add(:certificate, 'valid for too long')
    end
  end

  def certificate_key_is_supported(x509cert)
    if x509cert.public_key.is_a?(OpenSSL::PKey::RSA)
      certificate_is_strong x509cert
    else
      self.errors.add(:certificate, 'in not RSA')
    end
  end

  def certificate_is_strong(x509cert)
    unless x509cert.public_key.params["n"].num_bits >= 2048
      self.errors.add(:certificate, 'key size is less than 2048')
    end
  end

  def valid_certificate(value)
    if value.include?("-----BEGIN CERTIFICATE-----")
      cert = OpenSSL::X509::Certificate.new(value)
    else
      cert = OpenSSL::X509::Certificate.new(Base64.decode64(value))
    end
    return cert
  rescue
    self.errors.add(:certificate, 'is not a valid x509 certificate')
    return nil
  end

end
