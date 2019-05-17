module Utilities
  module Certificate
    class CertificateFactory
      attr_reader :certificate
  
      def self.to_subject(cert)
        x509_certificate(cert).subject.to_s
      end

      def self.x509_certificate(cert)
        if cert != @last_converted_value || @x509_certificate.blank?
          @x509_certificate = create_openssl_certificate(cert)
          @last_converted_value = cert
        end
        @x509_certificate
      end

      def self.convert_value_to_inline_der(cert)
        Base64.strict_encode64(x509_certificate(cert).to_der)
      end

      def self.create_openssl_certificate(cert_value)
        @certificate = OpenSSL::X509::Certificate.new(cert_value)
      rescue
        @certificate = OpenSSL::X509::Certificate.new(Base64.decode64(cert_value))
      end
    end
  end
end
