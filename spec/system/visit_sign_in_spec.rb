require 'rails_helper'

RSpec.describe 'Sign in', type: :system do
  include CognitoSupport

  scenario 'user cannot sign in if not registered' do
    SelfService.service(:cognito_client).stub_responses(:initiate_auth, Aws::CognitoIdentityProvider::Errors::UserNotFoundException.new(nil, "Stub Response"))
    
    sign_in('unregistered@example.com', 'testtest')

    expect(current_path).to eql new_user_session_path
    expect(page).to have_content t('devise.failure.user.invalid_login')
  end

  scenario 'user can sign in with valid credentials' do
    setup_simple_auth_stub
    user = FactoryBot.create(:user)
    sign_in(user.email, user.password)

    expect(current_path).to eql root_path
  end

  scenario 'user cant sign in with unsigned jwt' do
    user_hash = CognitoStubClient.stub_user_hash(role: ROLE::GDS, email_domain: "digital.cabinet-office.gov.uk", groups: %w[gds])
    payload, headers = user_hash, { kid: SelfService.service(:jwks).jwk.kid }
    token = JWT.encode(payload, SelfService.service(:jwks).jwk.keypair, 'none')

    stub_cognito_response(method: :initiate_auth, payload: { authentication_result: { access_token: 'valid-token', id_token: token } })
    user = FactoryBot.create(:user)
    sign_in(user.email, user.password)

    expect(current_path).to eql new_user_session_path
    expect(page).to have_content t('devise.failure.user.unknown_cognito_response')
  end

  scenario 'user can sign in with valid 2FA credentials' do
    setup_2fa_stub

    user = FactoryBot.create(:user_manager_user)
    sign_in(user.email, user.password)
    expect(current_path).to eql new_user_session_path
    expect(page).to have_content t('login.mfa_heading')

    fill_in "user[totp_code]", with: "000000"
    click_button(t('login.login'))
    expect(current_path).to eql root_path
    # Ensure session is cleaned up from flow
    expect(page.get_rack_session.has_key?(:cognito_session_id)).to eql false
    expect(page.get_rack_session.has_key?(:challenge_name)).to eql false
    expect(page.get_rack_session.has_key?(:challenge_parameters)).to eql false
  end

  scenario 'user can abandon the sign-in flow' do
    setup_2fa_stub

    user = FactoryBot.create(:user_manager_user)
    sign_in(user.email, user.password)
    expect(current_path).to eql new_user_session_path
    expect(page).to have_content t('login.mfa_heading')
    old_session_id = page.get_rack_session_key('session_id')
    visit root_path
    click_link(t('login.cancel'))

    expect(current_path).to eql new_user_session_path
    expect(page).to have_content t('login.heading')
    expect(page.get_rack_session.length).to eql 1
    expect(page.get_rack_session_key('session_id')).not_to eql old_session_id
  end

  scenario 'user cant sign in with wrong 2FA credentials' do
    stub_cognito_response(method: :initiate_auth, payload: { challenge_name: "SOFTWARE_TOKEN_MFA", session: SecureRandom.uuid, challenge_parameters: { 'USER_ID_FOR_SRP' => '0000-0000' }})
    SelfService.service(:cognito_client).stub_responses(:respond_to_auth_challenge, Aws::CognitoIdentityProvider::Errors::CodeMismatchException.new(nil, "Stub Response"))

    user = FactoryBot.create(:user_manager_user)
    sign_in(user.email, user.password)
    expect(current_path).to eql new_user_session_path
    expect(page).to have_content t('login.mfa_heading')

    fill_in "user[totp_code]", with: "999999"
    click_button(t('login.login'))
    expect(current_path).to eql new_user_session_path
    expect(page).to have_content t('devise.failure.user.invalid_login')
  end

  scenario 'user cannot sign in with wrong email' do
    SelfService.service(:cognito_client).stub_responses(:initiate_auth, Aws::CognitoIdentityProvider::Errors::UserNotFoundException.new(nil, "Stub Response"))

    user = FactoryBot.create(:user_manager_user)
    sign_in('invalid@email.com', user.password)

    expect(current_path).to eql new_user_session_path
    expect(page).to have_content t('devise.failure.user.invalid_login')
  end

  scenario 'user cannot sign in with wrong password' do
    user = FactoryBot.create(:user_manager_user)
    sign_in(user.email, 'invalidpassword')

    expect(current_path).to eql new_user_session_path
    expect(page).to have_content t('devise.failure.user.invalid_login')
  end

  scenario 'user cannot sign in with an expired password' do
    SelfService.service(:cognito_client).stub_responses(:initiate_auth, Aws::CognitoIdentityProvider::Errors::NotAuthorizedException.new(nil, 'Temporary password has expired and must be reset by an administrator.'))
    user = FactoryBot.create(:user_manager_user)
    sign_in(user.email, 'expiredpassword')

    expect(current_path).to eql new_user_session_path
    expect(page).to have_content t('devise.failure.user.temporary_password_expired')
  end

  scenario 'user cannot access pages if not signed in' do
    visit new_msa_component_path

    expect(current_path).to eql new_user_session_path
    expect(page).to have_content t('devise.failure.unauthenticated')
  end

  scenario 'user is forced to change their temporary password' do
    setup_2fa_stub
    stub_cognito_response(method: :initiate_auth, payload: { challenge_name: "NEW_PASSWORD_REQUIRED", session: SecureRandom.uuid, challenge_parameters: { 'USER_ID_FOR_SRP' => '0000-0000' }})

    user = FactoryBot.create(:user_manager_user)
    sign_in(user.email, user.password)
    expect(current_path).to eql new_user_session_path
    expect(page).to have_content t('login.new_password_heading')

    fill_in "user[new_password]", with: "000000"
    click_button(t('login.login'))
    expect(current_path).to eql root_path
    # Ensure session is cleaned up from flow
    expect(page.get_rack_session.has_key?(:cognito_session_id)).to eql false
    expect(page.get_rack_session.has_key?(:challenge_name)).to eql false
    expect(page.get_rack_session.has_key?(:challenge_parameters)).to eql false
  end

  scenario 'User get prompted to setup MFA on first sign in' do
    stub_cognito_response(method: :initiate_auth, payload: { challenge_name: "MFA_SETUP", session: SecureRandom.uuid, challenge_parameters: { 'USER_ID_FOR_SRP' => '0000-0000' }})
    stub_cognito_response(method: :associate_software_token, payload: { secret_code: 'OC7YQ4VYEVRWQGIKSXV25B3MZUV355I5XUKKM4P7KGTO72OTXXUQ', session: SecureRandom.uuid })
    stub_cognito_response(method: :verify_software_token, payload: { status: "SUCCESS", session: SecureRandom.uuid })

    user = FactoryBot.create(:user_manager_user)
    sign_in(user.email, user.password)
    expect(current_path).to eql new_user_session_path
    expect(page).to have_content t('mfa_enrolment.heading')
    expect(page).to have_selector(".mfa-qr-code svg")

    fill_in "user[totp_code]", with: "000000"
    click_button(t('login.login'))

    expect(current_path).to eql root_path
    # Ensure session is cleaned up from flow
    expect(page.get_rack_session.has_key?(:cognito_session_id)).to eql false
    expect(page.get_rack_session.has_key?(:challenge_name)).to eql false
    expect(page.get_rack_session.has_key?(:challenge_parameters)).to eql false
  end

  scenario 'User is told when they enter a wrong code on setup and gets to try again' do
    SelfService.register_service(name: :cognito_client, client: Aws::CognitoIdentityProvider::Client.new(stub_responses: true))
    stub_cognito_response(method: :initiate_auth, payload: { challenge_name: "MFA_SETUP", session: SecureRandom.uuid, challenge_parameters: { 'USER_ID_FOR_SRP' => '0000-0000' }})
    stub_cognito_response(method: :associate_software_token, payload: { secret_code: 'OC7YQ4VYEVRWQGIKSXV25B3MZUV355I5XUKKM4P7KGTO72OTXXUQ', session: SecureRandom.uuid })
    stub_cognito_response(method: :verify_software_token, payload: 'EnableSoftwareTokenMFAException')
    user = FactoryBot.create(:user_manager_user)
    sign_in(user.email, user.password)
    expect(current_path).to eql new_user_session_path
    expect(page).to have_content t('mfa_enrolment.heading')
    expect(page).to have_selector(".mfa-qr-code svg")

    fill_in "user[totp_code]", with: "000000"
    click_button(t('login.login'))

    expect(current_path).to eql new_user_session_path
    expect(page).to have_content t('devise.sessions.EnableSoftwareTokenMFAException')
    # Ensure session is cleaned up from flow
    expect(page.get_rack_session.has_key?(:cognito_session_id)).to eql false
    expect(page.get_rack_session.has_key?(:challenge_name)).to eql false
    expect(page.get_rack_session.has_key?(:challenge_parameters)).to eql false
  end
end
