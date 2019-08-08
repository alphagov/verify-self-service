require 'rails_helper'
RSpec.describe 'Sign out', type: :system do
  scenario 'user can sign out' do
    SelfService.service(:cognito_client).stub_responses(:initiate_auth, { authentication_result: {access_token: "valid-token" }})

    user = FactoryBot.create(:user)
    sign_in(user.email, user.password)
    expect(page).to have_content 'Signed in successfully.'
    click_link 'Sign out'

    expect(current_path).to eql new_user_session_path
    expect(page).to have_content 'You need to sign in or sign up before continuing.'
  end

  scenario 'user signed out after inactiviy' do
    SelfService.service(:cognito_client).stub_responses(:initiate_auth, { authentication_result: {access_token: "valid-token" }})
    SelfService.service(:cognito_client).stub_responses(:get_user, { username: '00000000-0000-0000-0000-000000000000', user_attributes:
      [
        { name: 'sub', value: '00000000-0000-0000-0000-000000000000' },
        { name: 'custom:roles', value: 'test' },
        { name: 'email_verified', value: 'true' },
        { name: 'phone_number_verified', value: 'true' },
        { name: 'phone_number', value: '+447000000000' },
        { name: 'given_name', value: 'Test' },
        { name: 'family_name', value: 'User' },
        { name: 'email', value: 'test@test.test' }
      ],
    preferred_mfa_setting: 'SOFTWARE_TOKEN_MFA',
    user_mfa_setting_list: ['SOFTWARE_TOKEN_MFA'] })

    user = FactoryBot.create(:user)
    sign_in(user.email, user.password)
    travel_to Time.now + 16.minutes
    visit(profile_path)
    expect(current_path).to eql new_user_session_path
    expect(page).to have_content 'Your session expired. Please sign in again to continue.'
  end

  scenario 'user signed out after length of time' do
    SelfService.service(:cognito_client).stub_responses(:initiate_auth, { authentication_result: {access_token: "valid-token" }})
    SelfService.service(:cognito_client).stub_responses(:get_user, { username: '00000000-0000-0000-0000-000000000000', user_attributes:
      [
        { name: 'sub', value: '00000000-0000-0000-0000-000000000000' },
        { name: 'custom:roles', value: 'test' },
        { name: 'email_verified', value: 'true' },
        { name: 'phone_number_verified', value: 'true' },
        { name: 'phone_number', value: '+447000000000' },
        { name: 'given_name', value: 'Test' },
        { name: 'family_name', value: 'User' },
        { name: 'email', value: 'test@test.test' }
      ],
    preferred_mfa_setting: 'SOFTWARE_TOKEN_MFA',
    user_mfa_setting_list: ['SOFTWARE_TOKEN_MFA'] })

    user = FactoryBot.create(:user)
    sign_in(user.email, user.password)
    travel_to Time.now + 14.minutes
    visit(profile_path)
    expect(current_path).to eql profile_path
    travel_to Time.now + 16.minutes
    visit(profile_path)
    expect(current_path).to eql new_user_session_path
    expect(page).to have_content 'Your session expired. Please sign in again to continue.'
  end

  scenario 'user gets to path before expiry' do
    SelfService.service(:cognito_client).stub_responses(:initiate_auth, { authentication_result: {access_token: "valid-token" }})
    SelfService.service(:cognito_client).stub_responses(:get_user, { username: '00000000-0000-0000-0000-000000000000', user_attributes:
      [
        { name: 'sub', value: '00000000-0000-0000-0000-000000000000' },
        { name: 'custom:roles', value: 'test' },
        { name: 'email_verified', value: 'true' },
        { name: 'phone_number_verified', value: 'true' },
        { name: 'phone_number', value: '+447000000000' },
        { name: 'given_name', value: 'Test' },
        { name: 'family_name', value: 'User' },
        { name: 'email', value: 'test@test.test' }
      ],
    preferred_mfa_setting: 'SOFTWARE_TOKEN_MFA',
    user_mfa_setting_list: ['SOFTWARE_TOKEN_MFA'] })

    user = FactoryBot.create(:user)
    sign_in(user.email, user.password)
    travel_to Time.now + 14.minutes
    visit(profile_path)
    expect(current_path).to eql profile_path
  end
end
