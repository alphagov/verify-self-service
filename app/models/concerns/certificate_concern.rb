module CertificateConcern
  extend ActiveSupport::Concern

  BEGIN_CERT = '-----BEGIN CERTIFICATE-----'.freeze
  END_CERT = '-----END CERTIFICATE-----'.freeze

  def to_x509(value)
    OpenSSL::X509::Certificate.new(value)
  rescue # rubocop:disable Style/RescueStandardError
    OpenSSL::X509::Certificate.new(Base64.decode64(value))
  rescue # rubocop:disable Style/RescueStandardError
    OpenSSL::X509::Certificate.new(strip_cert(value))
  end

  def strip_cert(value)
    if value.include?(BEGIN_CERT) && value.include?(END_CERT)
      value.split(BEGIN_CERT).last.split(END_CERT).first
    end
  end
end
