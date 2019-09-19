class CertificateExtractor
  include ActiveModel::Model
  include CertificateConcern

  validate :file_content_type, :contents, if: :cert_file

  MIME_X509_CA = 'application/x-x509-ca-cert'.freeze
  MIME_PEM = 'application/x-pem-file'.freeze
  VALID_CONTENT_TYPES = [MIME_X509_CA, MIME_PEM].freeze

  def initialize(certificate)
    @value = certificate[:value]
    @cert_file = certificate[:cert_file]
  end

  def call
    return value unless cert_file
    contents.to_s
  end

private

  attr_reader :cert_file, :value

  def file_content_type
    unless VALID_CONTENT_TYPES.include?(cert_file.content_type)
      errors.add(:certificate, I18n.t('certificates.errors.invalid_file_type'))
    end
  end

  def contents
    @contents ||= begin
      to_x509(File.read(cert_file.tempfile))
    rescue OpenSSL::X509::CertificateError
      errors.add(:certificate, I18n.t('certificates.errors.invalid'))
    end
  end
end
