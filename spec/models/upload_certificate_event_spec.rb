require 'rails_helper'
require_relative '../support/certificate_support'
require_relative '../support/pki'

include CertificateSupport

RSpec.describe UploadCertificateEvent, type: :model do

  root = PKI.new
  good_cert = root.sign(generate_cert_with_expiry(Time.now + 2.months))
  good_cert_value = Base64.strict_encode64(good_cert.to_der)

  include_examples 'has data attributes', UploadCertificateEvent, [:usage, :value]
  include_examples 'is aggregated', UploadCertificateEvent, {usage: 'signing', value: good_cert_value }
  include_examples 'is a creation event', UploadCertificateEvent, {usage: 'signing', value: good_cert_value}

  context '#value' do
    it 'must be present' do
      event = UploadCertificateEvent.create()
      expect(event).to_not be_valid
      expect(event.errors[:value]).to eql ['can\'t be blank']
    end
  end

  context '#certificate' do

    let(:root){PKI.new}

    it 'must error with invalid x509 certificate' do
      event = UploadCertificateEvent.create(usage: 'signing', value: 'Not a valid certificate')
      expect(event).to_not be_valid
      expect(event.errors[:certificate]).to eql ['is not a valid x509 certificate']
    end

    it 'must allow base64 encoded DER format x509 certificate' do
      cert = generate_cert_with_expiry Time.now + 2.months
      root.sign cert

      event = UploadCertificateEvent.create(usage: 'signing', value: Base64.encode64(cert.to_der))
      expect(event).to be_valid
      expect(event.errors[:certificate]).to be_empty
    end

    it 'must allow PEM format x509 certificate' do
      cert = generate_cert_with_expiry Time.now + 2.months
      root.sign cert

      event = UploadCertificateEvent.create(usage: 'signing', value: cert.to_pem)
      expect(event).to be_valid
      expect(event.errors[:certificate]).to be_empty
    end

    it 'must not be expired' do
      cert = generate_cert_with_expiry Time.now - 1.months
      root.sign cert

      event = UploadCertificateEvent.create(usage: 'signing', value: Base64.encode64(cert.to_der))
      expect(event).to_not be_valid
      expect(event.errors[:certificate]).to eql ['has expired']
    end

    it 'must not expire within 1 month' do
      cert = generate_cert_with_expiry Time.now + 15.days
      root.sign cert

      event = UploadCertificateEvent.create(usage: 'signing', value: Base64.encode64(cert.to_der))
      expect(event).to_not be_valid
      expect(event.errors[:certificate]).to eql ['expires too soon']
    end

    it 'must expire within 1 year' do
      cert = generate_cert_with_expiry Time.now + 2.years
      root.sign cert

      event = UploadCertificateEvent.create(usage: 'signing', value: Base64.encode64(cert.to_der))
      expect(event).to_not be_valid
      expect(event.errors[:certificate]).to eql ['valid for too long']
    end

    it 'must be RSA' do
      cert = generate_ec_cert_and_key(Time.now + 6.months)[0]
      root.sign cert

      event = UploadCertificateEvent.create(usage: 'signing', value: Base64.encode64(cert.to_der))
      expect(event).to_not be_valid
      expect(event.errors[:certificate]).to eql ['in not RSA']
    end

    it 'must be at least 2048 bits' do
      cert = generate_rsa_cert_and_key(1024, Time.now + 6.months)[0]
      root.sign cert

      event = UploadCertificateEvent.create(usage: 'signing', value: Base64.encode64(cert.to_der))
      expect(event).to_not be_valid
      expect(event.errors[:certificate]).to eql ['key size is less than 2048']
    end

  end

  context '#usage' do
    it 'must be present' do
      event = UploadCertificateEvent.create()
      expect(event).to_not be_valid
      expect(event.errors[:usage]).to eql ['is not included in the list']
    end

    it 'must be signing or encryption' do
      event = UploadCertificateEvent.create(usage: 'foobar')
      expect(event).to_not be_valid
      expect(event.errors[:usage]).to eql ['is not included in the list']
    end

    it 'happy when signing' do
      event = UploadCertificateEvent.create(usage: 'signing')
      expect(event).to_not be_valid
      expect(event.errors[:usage]).to be_empty
    end

    it 'happy when encryption' do
      event = UploadCertificateEvent.create(usage: 'encryption')
      expect(event).to_not be_valid
      expect(event.errors[:usage]).to be_empty
    end
  end

end
