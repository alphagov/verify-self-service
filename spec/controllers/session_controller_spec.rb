# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  it 'Get to signin page' do
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
    SelfService.service(:cognito_client).stub_responses(:initiate_auth, challenge_name: challenge_name, session: cognito_session_id, challenge_parameters: { 'FRIENDLY_DEVICE_NAME' => 'Authy' })
    @request.env['devise.mapping'] = Devise.mappings[:user]
    post :create, params: { user: { email: username, password: 'validpass' } }
    expect(response).to have_http_status(:redirect)
    expect(session[:cognito_session_id]).to eq(cognito_session_id)
    expect(session[:challenge_name]).to eq(challenge_name)
    expect(subject).to redirect_to(new_user_session_path)
  end

  it 'Return to index if users successfully responds to TOTP request' do
    strategy = Devise::Strategies::RemoteAuthenticatable.new(nil)
    SelfService.service(:cognito_client).stub_responses(:respond_to_auth_challenge, authentication_result: { access_token: 'valid-token' })
    allow(request).to receive(:headers).and_return(user: 'name')
    allow(strategy).to receive(:params).at_least(:once).and_return(user: 'name')
    session[:challenge_name] = 'SOFTWARE_TOKEN_MFA'
    session[:cognito_session_id] = SecureRandom.uuid
    session[:challenge_parameters] = { 'FRIENDLY_DEVICE_NAME' => 'Authy', 'USER_ID_FOR_SRP' => '0000-0000' }
    @request.env['devise.mapping'] = Devise.mappings[:user]
    post :create, params: { user: { email: 'test@test.com', totp_code: '999999' } }
    expect(response).to have_http_status(:redirect)
    expect(subject).to redirect_to(root_path)
    expect(session[:challenge_name]).to be_nil
    expect(session[:cognito_session_id]).to be_nil
    expect(session[:challenge_parameters]).to be_nil
  end
end
