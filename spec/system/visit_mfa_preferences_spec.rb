require 'rails_helper'

RSpec.describe 'MFA Preferences page', type: :system do
  include NotifySupport
  before(:each) do
    login_user
  end

  context 'warning page' do
    it 'shows content' do
      visit profile_update_mfa_path
      
      expect(page).to have_content t('profile.mfa_warning.heading')
      expect(page).to have_content t('profile.mfa_warning.body')
      expect(page).to have_content t('profile.mfa_warning.warning')
      expect(current_path).to eql profile_update_mfa_path
    end
  end

  context 'mfa preferences page' do
    it 'visitng, gives a code, clicking change returns to profile' do
      secret_code = 'OC7YQ4VYEVRWQGIKSXV25B3MZUV355I5XUKKM4P7KGTO72OTXXUQ'
      stub_cognito_response(method: :associate_software_token, payload: { secret_code: secret_code })
      stub_cognito_response(method: :verify_software_token, payload: { status: "SUCCESS" })
      stub_notify_response
      visit profile_update_mfa_get_code_path
      expect(current_path).to eql profile_update_mfa_get_code_path
      expect(page).to have_content secret_code
      expect(page).to have_selector("#qr-code svg")

      fill_in "mfa_enrolment_form[totp_code]", with: "000000"
      click_button(t('profile.confirm'))

      expect(current_path).to eql profile_path
    end
  end

  context 'mfa preferences journey' do
  end
end
