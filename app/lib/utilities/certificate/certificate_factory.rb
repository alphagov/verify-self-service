# frozen_string_literal: true
module Utilities

  module Certificate

    class CertificateFactory
      attr_reader :certificate
      def initialize(value)
        @certificate = OpenSSL::X509::Certificate.new(value)
      rescue
        @certificate = OpenSSL::X509::Certificate.new(Base64.decode64(value))
      end

      def to_subject
        certificate.subject.to_s
      end
    end
  end
end