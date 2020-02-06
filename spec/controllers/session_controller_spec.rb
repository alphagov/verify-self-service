require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  include AuthSupport, CognitoSupport

  it 'Get to sign_in page' do
    @request.env['devise.mapping'] = Devise.mappings[:user]
    get :new
    expect(response).to have_http_status(:success)
  end

  it 'Redirect to TOTP form when user has MFA setup' do
    strategy = Devise::Strategies::RemoteAuthenticatable.new(nil)
    allow(request).to receive(:headers).and_return(user: 'name')
    cognito_session_id = SecureRandom.uuid
    username = 'test@test.com'
    challenge_name = 'SOFTWARE_TOKEN_MFA'
    stub_cognito_response(method: :initiate_auth, payload: { challenge_name: challenge_name, session: cognito_session_id, challenge_parameters: { } })
    @request.env['devise.mapping'] = Devise.mappings[:user]
    post :create, params: { user: { email: username, password: 'validpass' } }
    expect(response).to have_http_status(:redirect)
    expect(session[:cognito_session_id]).to eq(cognito_session_id)
    expect(session[:challenge_name]).to eq(challenge_name)
    expect(subject).to redirect_to(new_user_session_path)
  end

  it 'Return to index if users successfully responds to TOTP request' do
    strategy = Devise::Strategies::RemoteAuthenticatable.new(nil)
    setup_stub
    allow(request).to receive(:headers).and_return(user: 'name')
    allow(strategy).to receive(:params).at_least(:once).and_return(user: 'name')
    session[:challenge_name] = 'SOFTWARE_TOKEN_MFA'
    session[:cognito_session_id] = SecureRandom.uuid
    session[:challenge_parameters] = { 'USER_ID_FOR_SRP' => '0000-0000' }
    @request.env['devise.mapping'] = Devise.mappings[:user]
    post :create, params: { user: { email: 'test@test.com', totp_code: '999999' } }
    expect(response).to have_http_status(:redirect)
    expect(subject).to redirect_to(root_path)
    expect(session[:challenge_name]).to be_nil
    expect(session[:cognito_session_id]).to be_nil
    expect(session[:challenge_parameters]).to be_nil
  end

  it 'Redirect to new password set-up when the user is using a temporary password' do
    strategy = Devise::Strategies::RemoteAuthenticatable.new(nil)
    allow(request).to receive(:headers).and_return(user: 'name')
    cognito_session_id = SecureRandom.uuid
    username = 'test@test.com'
    challenge_name = 'NEW_PASSWORD_REQUIRED'
    stub_cognito_response(method: :initiate_auth, payload: { challenge_name: challenge_name, session: cognito_session_id, challenge_parameters: { } })
    @request.env['devise.mapping'] = Devise.mappings[:user]
    post :create, params: { user: { email: username, password: 'validpass' } }
    expect(response).to have_http_status(:redirect)
    expect(session[:cognito_session_id]).to eq(cognito_session_id)
    expect(session[:challenge_name]).to eq(challenge_name)
    expect(subject).to redirect_to(new_user_session_path)
  end

  it 'Return to index if users successfully set their new password' do
    strategy = Devise::Strategies::RemoteAuthenticatable.new(nil)
    setup_stub
    allow(request).to receive(:headers).and_return(user: 'name')
    allow(strategy).to receive(:params).at_least(:once).and_return(user: 'name')
    session[:challenge_name] = 'NEW_PASSWORD_REQUIRED'
    session[:cognito_session_id] = SecureRandom.uuid
    session[:challenge_parameters] = { 'USER_ID_FOR_SRP' => '0000-0000' }
    @request.env['devise.mapping'] = Devise.mappings[:user]
    post :create, params: { user: { email: 'test@test.com', new_password: 'mynewpassword' } }
    expect(response).to have_http_status(:redirect)
    expect(subject).to redirect_to(root_path)
    expect(session[:challenge_name]).to be_nil
    expect(session[:cognito_session_id]).to be_nil
    expect(session[:challenge_parameters]).to be_nil
  end

  it 'Redirect user straight to reset password page if user password has been reset' do
    allow(request).to receive(:headers).and_return(user: 'name')
    stub_cognito_response(method: :initiate_auth, payload: 'PasswordResetRequiredException')
    username = 'test@test.com'
    @request.env['devise.mapping'] = Devise.mappings[:user]
    post :create, params: { user: { email: username, password: 'validpass' } }
    expect(response).to have_http_status(:redirect)
    expect(subject).to redirect_to(force_user_reset_password_path(username, true))
  end

  it 'Renders sign_user_form if user param is not present' do
    allow(request).to receive(:headers).and_return(user: 'name')
    stub_cognito_response(method: :initiate_auth, payload: 'PasswordResetRequiredException')
    username = 'test@test.com'
    @request.env['devise.mapping'] = Devise.mappings[:user]
    post :create, params: { user: nil }
    expect(response).to have_http_status(:success)
    expect(response).to render_template(:new)
  end

  def setup_stub
    user_hash = CognitoStubClient.stub_user_hash(role: ROLE::GDS, email_domain: TEAMS::GDS_EMAIL_DOMAIN, groups: %w[gds])
    token = CognitoStubClient.user_hash_to_jwt(user_hash)
    stub_cognito_response(method: :respond_to_auth_challenge, payload: { authentication_result: { access_token: 'valid-token', id_token: token } })
  end
end
