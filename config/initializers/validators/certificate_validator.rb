ActiveRecord::Base.class_eval do

  def self.value_is_present(value)
    validate :value, :value_is_present
  end

  def self.certificate_is_new(value)
    validate :value, :certificate_is_new, on: :create, if: :value_present?
  end

  def self.component_is_persisted(component_id)
    validate :component_id, :component_is_persisted
  end

  def self.certificate_is_valid(value)
    validate :value, :certificate_is_valid, on: :create, if: :value_present?
  end

  def certificate_is_valid
    return if x509_certificate.nil?

    certificate_has_appropriate_not_after
    certificate_key_is_supported
  end

  def factory
    Utilities::Certificate::CertificateFactory
  end

  def x509_certificate
    x509 = factory.x509_certificate(value)
  rescue
    errors.add(:certificate, 'is not a valid x509 certificate') if x509.nil?
    x509
  end
  
  def convert_value_to_inline_der
    factory.convert_value_to_inline_der(value)
  end

  def certificate_has_appropriate_not_after
    if x509_certificate.not_after < Time.now
      errors.add(:certificate, 'has expired')
    elsif x509_certificate.not_after < Time.now + 30.days
      errors.add(:certificate, 'expires too soon')
    elsif x509_certificate.not_after > Time.now + 1.year
      errors.add(:certificate, 'valid for too long')
    end
  end

  def certificate_key_is_supported
    if x509_certificate.public_key.is_a?(OpenSSL::PKey::RSA)
      certificate_is_strong
    else
      errors.add(:certificate, 'in not RSA')
    end
  end

  def certificate_is_strong
    return if x509_certificate.public_key.params['n'].num_bits >= 2048
    
    errors.add(:certificate, 'key size is less than 2048')
  end

  def value_is_present
    errors.add(:certificate, "can't be blank") unless value_present?
  end

  def value_present?
    value.present?
  end

  def certificate_is_new
    errors.add(:certificate, 'already exists') if certificate.persisted?
  end

  def component_is_persisted
    errors.add(:component, 'must exist') unless component&.persisted?
  end
 end
