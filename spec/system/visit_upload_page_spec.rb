require 'rails_helper'
require 'auth_test_helper'

include CertificateSupport

RSpec.describe 'UploadPage', type: :system do

  before(:each) do
    stub_auth
  end

  let(:root) { PKI.new }

  let(:test_certificate) do
    root.generate_encoded_cert(expires_in: 2.months)
  end

  it 'successfully submits a certificate' do
    visit '/upload'
    choose 'certificate_usage_signing', allow_label_click: true
    fill_in 'certificate_value', with: test_certificate
    click_button 'Upload'
    expect(page).to have_content test_certificate
    expect(current_path).to eql certificates_path
  end
end
