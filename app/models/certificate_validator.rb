class CertificateValidator < ActiveModel::EachValidator
  include X509Validator

  def validate_each(record, _attribute, value)
    valid_x509?(record, value)
  end
end
