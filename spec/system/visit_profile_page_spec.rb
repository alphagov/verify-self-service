require 'rails_helper'

RSpec.describe 'Profile page', type: :system do
  before(:each) do
    login_user
  end

  context 'profile page' do
    it 'should show profile page' do
      visit profile_path
      expect(page).to have_content t('profile.title')
      expect(current_path).to eql profile_path
    end

    it 'should show profile page with mfa setup' do
      user_info = { username: "00000000-0000-0000-0000-000000000000",
                    user_attributes: [],
                    mfa_options: nil,
                    preferred_mfa_setting: nil,
                    user_mfa_setting_list: nil,
                  }
      stub_cognito_response(method: :get_user, payload: user_info)
      visit profile_path

      expect(page).to have_content "#{t('profile.mfa')} #{t('profile.set_up')}"
      expect(current_path).to eql profile_path
    end

    it 'should show profile page with change mfa' do
      user_info = { username: "00000000-0000-0000-0000-000000000000",
                    user_attributes: [],
                    mfa_options: nil,
                    preferred_mfa_setting: "SOFTWARE_TOKEN_MFA",
                    user_mfa_setting_list: [ "SOFTWARE_TOKEN_MFA" ],
                  }
      stub_cognito_response(method: :get_user, payload: user_info)
      visit profile_path

      expect(page).to have_content "#{t('profile.mfa')} #{t('profile.software_token')} #{t('profile.change')}"
      expect(current_path).to eql profile_path
    end
  end
end

