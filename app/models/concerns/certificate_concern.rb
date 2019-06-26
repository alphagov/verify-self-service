module CertificateConcern
  extend ActiveSupport::Concern

  def to_x509(value)
    OpenSSL::X509::Certificate.new(value)
  rescue # rubocop:disable Style/RescueStandardError
    OpenSSL::X509::Certificate.new(Base64.decode64(value))
  end
end
