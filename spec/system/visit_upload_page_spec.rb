require 'rails_helper'
require_relative '../support/certificate_support'
require_relative '../support/pki'

include CertificateSupport

RSpec.describe 'UploadPage', type: :system do

  root = PKI.new
  good_cert = root.sign(generate_cert_with_expiry(Time.now + 2.months))
  good_cert_value = Base64.strict_encode64(good_cert.to_der)

  let(:test_certificate) { good_cert_value }
  it 'successfully submits a certificate' do
    visit '/upload'
    choose 'certificate_usage_signing', allow_label_click: true
    fill_in 'certificate_value', with: test_certificate
    click_button 'Upload'
    expect(page).to have_content test_certificate
    expect(current_path).to eql certificates_path
  end
end
