class UploadCertificateEvent < AggregatedEvent
  belongs_to_aggregate :certificate
  data_attributes :value, :usage, :component_id
  before_save :convert_value_to_inline_der

  validate :value_is_present
  validate :certificate_is_valid,
           :certificate_is_new, on: :create, if: :value_present?

  validate :component_is_persisted

  validates_inclusion_of :usage, in: ['signing', 'encryption']

  def build_certificate
    Certificate.new
  end

  def attributes_to_apply
    {usage: self.usage, value: self.value, component_id: self.component_id, created_at: self.created_at}
  end

  def component
    if @component&.id == self.component_id
      @component
    else
      @component = Component.find_by_id(self.component_id)
    end
  end

  def component=(component)
    self.component_id = component.id
    @component = component
  end

  private

  def component_is_persisted
    unless self.component&.persisted?
      self.errors.add(:component, "must exist")
    end
  end

  def convert_value_to_inline_der
    self.value = Base64.strict_encode64(x509_certificate.to_der)
  end

  def value_is_present
    unless value_present?
      self.errors.add(:certificate, "can't be blank")
    end
  end

  def value_present?
    self.value.present?
  end

  def certificate_is_new
    if self.certificate.persisted?
      self.errors.add(:certificate, 'already exists')
    end
  end

  def certificate_is_valid
    unless x509_certificate.nil?
      certificate_has_appropriate_not_after
      certificate_key_is_supported
    end
  end

  def certificate_has_appropriate_not_after
    if x509_certificate.not_after < Time.now
      self.errors.add(:certificate, 'has expired')
    elsif x509_certificate.not_after < Time.now + 30.days
      self.errors.add(:certificate, 'expires too soon')
    elsif x509_certificate.not_after > Time.now + 1.year
      self.errors.add(:certificate, 'valid for too long')
    end
  end

  def certificate_key_is_supported
    if x509_certificate.public_key.is_a?(OpenSSL::PKey::RSA)
      certificate_is_strong
    else
      self.errors.add(:certificate, 'in not RSA')
    end
  end

  def certificate_is_strong
    unless x509_certificate.public_key.params["n"].num_bits >= 2048
      self.errors.add(:certificate, 'key size is less than 2048')
    end
  end

  def x509_certificate
    if self.value != @last_converted_value || @x509_certificate.blank?
      @x509_certificate = convert_value_to_x509_certificate
      @last_converted_value = self.value
    end

    @x509_certificate
  rescue
    self.errors.add(:certificate, 'is not a valid x509 certificate')
    return @x509_certificate = nil
  end

  def convert_value_to_x509_certificate
    begin
      OpenSSL::X509::Certificate.new(self.value)
    rescue
      OpenSSL::X509::Certificate.new(Base64.decode64(self.value))
    end
  end
end
