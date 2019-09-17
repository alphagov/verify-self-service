class CertificateValidator < ActiveModel::EachValidator
  include X509Validator

  def validate_each(record, _attribute, value)
    x509 = x509_certificate(record, value)
    return false if x509.nil?

    certificate_has_appropriate_not_after(record, x509)
    certificate_key_is_supported(record, x509)
  end
end
