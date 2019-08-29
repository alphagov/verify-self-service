require 'support/cognito_support'

module System
  module SessionHelpers
    include CognitoSupport
  
    def sign_in(email, password)
      visit new_user_session_path
      fill_in 'Email', with: email
      fill_in 'Password', with: password
      click_button 'Log in'
    end

    def totp_sign_in(totp_code)
      fill_in 'user[totp_code]', with: totp_code
      click_button 'Log in'
    end

    def login_user
      user = FactoryBot.create(:user_manager_user)
      login_as(user, scope: :user)
    end

    def login_gds_user
      user = FactoryBot.create(:gds_user)
      login_as(user, scope: :user)
    end

    def login_component_manager_user
      user = FactoryBot.create(:component_manager_user)
      login_as(user, scope: :user)
    end

    def login_gds_user
      user = FactoryBot.create(:gds_user)
      login_as(user, :scope => :user)
    end

    def login_component_manager_user
      user = FactoryBot.create(:component_manager_user)
      login_as(user, :scope => :user)
    end

    def login_certificate_manager_user
      user = FactoryBot.create(:certificate_manager_user)
      login_as(user, scope: :user)
    end

    def setup_simple_auth_stub
      user_hash = CognitoStubClient.stub_user_hash(role: ROLE::GDS, email_domain: "digital.cabinet-office.gov.uk", groups: %w[gds])
      token = CognitoStubClient.user_hash_to_jwt(user_hash)
      stub_cognito_response(method: :initiate_auth, payload: { authentication_result: { access_token: 'valid-token', id_token: token } })
    end

    def setup_2fa_stub
      stub_cognito_response(method: :initiate_auth, payload: { challenge_name: "SOFTWARE_TOKEN_MFA", session: SecureRandom.uuid, challenge_parameters: { 'USER_ID_FOR_SRP' => '0000-0000' }})
      user_hash = CognitoStubClient.stub_user_hash(role: ROLE::GDS, email_domain: "digital.cabinet-office.gov.uk", groups: %w[gds])
      token = CognitoStubClient.user_hash_to_jwt(user_hash)
      stub_cognito_response(method: :respond_to_auth_challenge, payload: { authentication_result: { access_token: 'valid-token', id_token: token } })
    end
  end
end
