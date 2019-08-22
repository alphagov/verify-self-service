require 'rails_helper'
require 'rqrcode'
require 'erb'

RSpec.describe 'MFA enrolment', type: :system do
  include ERB::Util
  context 'is successful' do
    let(:secret_code_value) { 'secret-code-value'}
    let(:user_email) { 'mfa@test.com'}
    let(:qr_issuer) { url_encode("GOV.UK Verify Admin Tool (test)") }
    let(:qr_code_object) {
      RQRCode::QRCode.new("otpauth://totp/#{qr_issuer}:#{url_encode(user_email)}?secret=#{secret_code_value}&issuer=#{qr_issuer}")
    }
    scenario 'user is forced to enrol to MFA if not set up for it' do
      SelfService.service(:cognito_client).stub_responses(:associate_software_token, { secret_code: secret_code_value })
      SelfService.service(:cognito_client).stub_responses(:verify_software_token, {})
      user_hash = CognitoStubClient.stub_user_hash(role: ROLE::GDS, email_domain: "digital.cabinet-office.gov.uk", groups: %w[gds])
      user_hash.delete('mfa')
      user_hash['email'] = user_email
      token = CognitoStubClient.user_hash_to_jwt(user_hash)
      SelfService.service(:cognito_client).stub_responses(:initiate_auth, authentication_result: { access_token: 'valid-token', id_token: token })
  
      user = FactoryBot.create(:user_manager_user)
      sign_in(user.email, user.password)
      expect(current_path).to eql mfa_enrolment_path
      expect(page).to have_content 'Set up your MFA'
      expect(page).to have_content secret_code_value

      expect(page).to have_selector(".mfa-qr-code svg")
      # Couldn't make Capybara to read the SVG properly to compare, so comparing on size instead
      qr_code_size = qr_code_object.as_svg(module_size: 3).scan(/(?=rect)/).count
      expect(page.all(:css, '.mfa-qr-code svg rect').length).to eq qr_code_size

      fill_in "mfa_enrolment_form_code", with: "999999"
      click_button("commit")
      expect(current_path).not_to eql mfa_enrolment_path
    end
  end

  context 'is unsuccessful' do
    let(:secret_code_value) { 'secret-code-value'}
    let(:user_email) { 'mfa@test.com'}
    let(:qr_issuer) { url_encode("GOV.UK Verify Admin Tool (test)") }
    let(:qr_code_object) {
      RQRCode::QRCode.new("otpauth://totp/#{qr_issuer}:#{url_encode(user_email)}?secret=#{secret_code_value}&issuer=#{qr_issuer}")
    }
    scenario 'user gets an error when the MFA code is not valid' do
      SelfService.service(:cognito_client).stub_responses(:associate_software_token, { secret_code: secret_code_value })
      SelfService.service(:cognito_client).stub_responses(:get_user, { username: '00000000-0000-0000-0000-000000000000', user_attributes:
        [
          { name: 'sub', value: '00000000-0000-0000-0000-000000000000' },
          { name: 'custom:roles', value: 'usermgr' },
          { name: 'email_verified', value: 'true' },
          { name: 'phone_number_verified', value: 'true' },
          { name: 'phone_number', value: '+447000000000' },
          { name: 'given_name', value: 'Test' },
          { name: 'family_name', value: 'User' },
          { name: 'email', value: user_email }
        ],
      preferred_mfa_setting: nil,
      user_mfa_setting_list: [] })

      SelfService.service(:cognito_client).stub_responses(:verify_software_token, Aws::CognitoIdentityProvider::Errors::CodeMismatchException.new(nil, nil))
  
      user = FactoryBot.create(:user_manager_user)
      sign_in(user.email, user.password)
      expect(current_path).to eql mfa_enrolment_path
      expect(page).to have_content 'Set up your MFA'
      expect(page).to have_content secret_code_value

      fill_in "mfa_enrolment_form_code", with: "000000"
      click_button("commit")
      expect(current_path).to eql mfa_enrolment_path
      expect(page).to have_content 'There was an error, please try again'
    end
  end

  

end
