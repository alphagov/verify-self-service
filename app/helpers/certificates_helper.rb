module CertificatesHelper
  def convert_value_to_x509_certificate(value)
    begin
      OpenSSL::X509::Certificate.new(value)
    rescue
      OpenSSL::X509::Certificate.new(Base64.decode64(value))
    end
  end
end