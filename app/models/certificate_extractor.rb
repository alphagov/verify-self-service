class CertificateExtractor
  include ActiveModel::Model
  include CertificateConcern

  validate :file_content_type, :contents, if: :file_upload?

  MIME_X509_CA = "application/x-x509-ca-cert".freeze
  MIME_PEM = "application/x-pem-file".freeze
  VALID_CONTENT_TYPES = [MIME_X509_CA, MIME_PEM].freeze

  def initialize(params)
    @params = params
  end

  def call
    return params[:certificate][:value] unless file_upload?

    contents&.to_s
  end

private

  attr_reader :params

  def file_upload?
    @file_upload ||= params["upload-certificate"] == "file"
  end

  def file_content_type
    unless VALID_CONTENT_TYPES.include?(params[:certificate].dig(:cert_file)&.content_type)
      errors.add(:certificate, I18n.t("certificates.errors.invalid_file_type"))
    end
  end

  def contents
    @contents ||= begin
      tempfile = params[:certificate].dig(:cert_file)&.tempfile
      to_x509(File.read(tempfile)) if tempfile
    end
  rescue OpenSSL::X509::CertificateError
    errors.add(:certificate, I18n.t("certificates.errors.invalid"))
  end
end
