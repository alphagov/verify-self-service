require 'rails_helper'

RSpec.describe CertificateExtractor, type: :model do
  let(:cert) { PKI.new.generate_signed_cert }

  context 'file type validation' do
    it 'fails validation for invalid file types' do
      extractor = create_extractor(
        cert_file: upload_file(
          name: 'invalid.txt',
          type: 'text/rtf',
          content: 'In a hole in the ground there lived a hobbit'
        )
      )

      expect(extractor).to_not be_valid
      expect(extractor.errors.full_messages.first).to include(I18n.t('certificates.errors.invalid_file_type'))
    end

    it 'fails validation for private key files' do
      private_key = "-----BEGIN RSA PRIVATE KEY-----" \
                    "MIIEpQIBAAKCAQEA3Tz2mr7SZiAMfQyuvBjM9OiZ1BjP5CE/Wm/Rr500P" \
                    "RK+Lh9x5eJPo5CAZ3/ANBE0sTK0ZsDGMak2m1g73VHqIxFTz0Ta1d+NAj" \
                    "wnLe4nOb7/eEJbDPkk05ShhBrJGBKKxb8n104o/PdzbFMIyNjJzBM2o5y" \
                    "-----END RSA PRIVATE KEY-----"
      extractor = create_extractor(
        cert_file: upload_file(
          name: 'invalid.key',
          type: 'application/pkcs8',
          content: private_key
        )
      )

      expect(extractor).to_not be_valid
      expect(extractor.errors.full_messages.first).to include(I18n.t('certificates.errors.invalid_file_type'))
    end
  end

  context 'no cert file provided' do
    it 'passes back the string value' do
      expect(create_extractor(value: 'John Wick').call).to eq('John Wick')
    end
  end

  context 'valid certificate file provided' do
    it 'validates .crt files' do
      extractor = create_extractor(
        cert_file: upload_file(
          name: 'valid.crt',
          type: CertificateExtractor::MIME_X509_CA,
          content: cert.to_text + cert.public_key.to_s
        )
      )

      expect(extractor).to be_valid
      expect(extractor.errors.full_messages).to be_empty
    end

    it 'validates and extracts .pem files' do
      extractor = create_extractor(
        cert_file: upload_file(
          name: 'valid.pem',
          type: CertificateExtractor::MIME_PEM,
          content: cert.to_pem
        )
      )

      expect(extractor).to be_valid
      expect(extractor.errors.full_messages).to be_empty
      expect(extractor.call).to include(cert.to_pem)
    end

    it 'validates and extracts .der files' do
      extractor = create_extractor(
        cert_file: upload_file(
          name: 'valid.der',
          type: CertificateExtractor::MIME_X509_CA,
          content: Base64.strict_encode64(cert.to_der)
        )
      )

      expect(extractor).to be_valid
      expect(extractor.errors.full_messages).to be_empty
      expect(extractor.call).to include(cert.to_pem)
    end
  end

  def create_extractor(value: '', cert_file: nil)
    CertificateExtractor.new(value: value, cert_file: cert_file)
  end

  def upload_file(name:, type:, content:)
    ActionDispatch::Http::UploadedFile.new(
      filename: name,
      head: 'Content-Disposition: form-data; name=certificate[cert_file]',
      type: type,
      tempfile: create_tempfile(name: name, content: content)
    )
  end

  def create_tempfile(name:, content:)
    Tempfile.new(name).tap do |f|
      f.write(content)
      f.close
    end
  end
end
