module CertificateSupport

  def generate_cert_with_expiry(expiry, cn = "GENERATED TEST CERTIFICATE")
    generate_rsa_cert_and_key(2048, expiry, cn)[0]
  end

  def generate_cert(cn = "GENERATED TEST CERTIFICATE")
    generate_rsa_cert_and_key(2048, (Time.now + 1.year), cn)[0]
  end

  def generate_rsa_cert_and_key(size, expiry, cn = "GENERATED TEST CERTIFICATE")
    key = OpenSSL::PKey::RSA.new size
    generate_cert_using_key(key.public_key, expiry, cn)
  end

  def generate_ec_cert_and_key(expiry, cn = "GENERATED TEST CERTIFICATE")
    ec_key = OpenSSL::PKey::EC.new('prime256v1').generate_key!
    point = ec_key.public_key
    key = OpenSSL::PKey::EC.new(point.group)
    key.public_key = point
    generate_cert_using_key(key, expiry, cn)
  end

  def generate_cert_using_key(public_key, expiry, cn = "GENERATED TEST CERTIFICATE")
    cert = OpenSSL::X509::Certificate.new
    cert.version = 2
    cert.subject = OpenSSL::X509::Name.parse "/DC=org/DC=TEST/CN=#{cn}"
    cert.public_key = public_key
    cert.not_before = expiry - 5.years
    cert.not_after = expiry
    [cert, public_key]
  end

  def inline_pem(cert)
    Base64.encode64(cert.to_der)
  end
end
