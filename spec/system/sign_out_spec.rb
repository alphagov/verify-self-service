require 'rails_helper'

def cognito_stubs
  user_hash = CognitoStubClient.stub_user_hash(role: ROLE::GDS, email_domain: "digital.cabinet-office.gov.uk", groups: %w[gds])
  token = CognitoStubClient.user_hash_to_jwt(user_hash)
  stub_cognito_response(method: :initiate_auth, payload: { authentication_result: { access_token: 'valid-token', id_token: token } })
end

RSpec.describe 'Sign out', type: :system do
  scenario 'user can sign out' do
    cognito_stubs

    user = FactoryBot.create(:user_manager_user)
    sign_in(user.email, user.password)
    click_link t('layout.application.sign_out_link')

    expect(current_path).to eql new_user_session_path
    expect(page).to have_content t('devise.failure.unauthenticated')
  end

  scenario 'user signed out after inactiviy' do
    Rails.configuration.session_expiry_in_minutes = 90.minutes
    Rails.configuration.session_inactivity_in_minutes = 15.minutes
    cognito_stubs

    user = FactoryBot.create(:user_manager_user)
    sign_in(user.email, user.password)
    travel_to Time.now + 16.minutes
    visit(profile_path)
    expect(current_path).to eql new_user_session_path
  end

  scenario 'user signed out after length of time' do
    Rails.configuration.session_expiry = 15.minutes
    Rails.configuration.session_inactivity = 60.minutes
    cognito_stubs

    user = FactoryBot.create(:user_manager_user)
    sign_in(user.email, user.password)
    travel_to Time.now + 14.minutes
    visit(profile_path)
    expect(current_path).to eql profile_path
    travel_to Time.now + 16.minutes
    visit(profile_path)
    expect(current_path).to eql new_user_session_path
    expect(page).to have_content t('devise.failure.timeout')
  end

  scenario 'user gets to path before expiry' do
    cognito_stubs
    Rails.configuration.session_inactivity_in_minutes = 15.minutes

    user = FactoryBot.create(:user_manager_user)
    sign_in(user.email, user.password)
    travel_to Time.now + 14.minutes
    visit(profile_path)
    expect(current_path).to eql profile_path
  end
end
