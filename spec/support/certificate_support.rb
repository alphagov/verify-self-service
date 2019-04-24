module CertificateSupport
  def generate_cert(**args)
    generate_rsa_cert_and_key(args)[0]
  end

  def generate_rsa_cert_and_key(expires_in: 1.year, size: 2048, cn: "GENERATED TEST CERTIFICATE")
    key = OpenSSL::PKey::RSA.new size
    generate_cert_using_key(key.public_key, expires_in, cn)
  end

  def generate_ec_cert_and_key(expires_in: 1.year, size: 2048, cn: "GENERATED TEST CERTIFICATE")
    ec_key = OpenSSL::PKey::EC.new('prime256v1').generate_key!
    point = ec_key.public_key
    key = OpenSSL::PKey::EC.new(point.group)
    key.public_key = point
    generate_cert_using_key(key, expires_in, cn)
  end

  private

  def generate_cert_using_key(public_key, expires_in, cn)
    cert = OpenSSL::X509::Certificate.new
    cert.version = 2
    cert.subject = OpenSSL::X509::Name.parse "/DC=org/DC=TEST/CN=#{cn}"
    cert.public_key = public_key
    cert.not_before = Time.now - 5.years
    cert.not_after = Time.now + expires_in
    [cert, public_key]
  end

  def inline_pem(cert)
    Base64.encode64(cert.to_der)
  end

  def convert_value_to_x509_certificate(cert)
    begin
      OpenSSL::X509::Certificate.new(cert)
    rescue
      OpenSSL::X509::Certificate.new(Base64.decode64(cert))
    end
  end 
  
  def certificate_subject(cert)
    convert_value_to_x509_certificate(cert).subject.to_s
  end
end
