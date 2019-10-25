module X509Validator
  def valid_x509?(record, value = nil)
    x509_cert = x509_certificate(record, value || record.value)
    return false if x509_cert.nil?

    certificate_has_appropriate_not_after(record, x509_cert).nil? &&
      certificate_key_is_supported(record, x509_cert).nil?
  end

  def x509_certificate(record, value)
    load_as_x509_certificate(value).tap do |x509|
      record.errors.add(:certificate, I18n.t('certificates.errors.invalid')) if x509.nil?
    end
  end

  def load_value_as_x509_cert(value)
    OpenSSL::X509::Certificate.new(value)
  rescue OpenSSL::X509::CertificateError, TypeError
    nil
  end

  def certificate_has_appropriate_not_after(record, x509)
    if x509.not_after < Time.now
      record.errors.add(:certificate, I18n.t('certificates.errors.expired'))
    elsif x509.not_after < Time.now + 30.days
      record.errors.add(:certificate, I18n.t('certificates.errors.expires_soon'))
    elsif x509.not_after > Time.now + 1.year
      record.errors.add(:certificate, I18n.t('certificates.errors.valid_too_long'))
    end
  end

  def load_decoded_value_as_x509_cert(value)
    load_value_as_x509_cert(Base64.decode64(value)) unless value.nil?
  end

  def load_as_x509_certificate(value)
    load_value_as_x509_cert(value) || load_decoded_value_as_x509_cert(value)
  end

  def certificate_key_is_supported(record, x509)
    if x509.public_key.is_a?(OpenSSL::PKey::RSA)
      certificate_is_strong(record, x509)
    else
      record.errors.add(:certificate, I18n.t('certificates.errors.not_rsa'))
    end
  end

  def certificate_is_strong(record, x509)
    if x509.public_key.params['n'].num_bits >= 2048
      certificate_digest_right(record, x509)
    else
      record.errors.add(:certificate, I18n.t('certificates.errors.small_key'))
    end
  end

  def valid_algorithms
    %w[sha256WithRSAEncryption sha384WithRSAEncryption sha512WithRSAEncryption]
  end

  def certificate_digest_right(record, x509)
    return if valid_algorithms.include?(x509.signature_algorithm)

    record.errors.add(:certificate, I18n.t('certificates.errors.bad_algorithm'))
  end
end
