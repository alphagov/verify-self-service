require 'rails_helper'

RSpec.describe MfaController, type: :controller do
  include AuthSupport, CognitoSupport

  describe '#index' do
    it 'renders the page when asked to enrol to MFA' do
      stub_cognito_response(method: :associate_software_token, payload: { secret_code: 'abcdefgh' })
      session[:email] = 'test@test.test'
      session[:access_token] = 'valid-access-token'
      get :index
      expect(response).to have_http_status(:success)
      expect(subject).to render_template(:index)
    end

    it 'redirects when the user has an invalid session' do
      get :index
      expect(response).to have_http_status(:redirect)
      expect(subject).to redirect_to(root_path)
    end

    it 'redirects when the user is already logged in' do
      usermgr_stub_auth
      session[:access_token] = 'valid-access-token'
      get :index
      expect(response).to have_http_status(:redirect)
      expect(subject).to redirect_to(root_path)
    end
  end

  describe '#enrol' do
    it 'is success when successfully enrolled' do
      stub_cognito_response(method: :verify_software_token)
      stub_cognito_response(method: :set_user_mfa_preference)
      session[:email] = 'test@test.test'
      session[:access_token] = "valid-access-token"
      post :enrol, params: { mfa_enrolment_form: { code: 12345 }}
      expect(response).to have_http_status(:redirect)
      expect(subject).to redirect_to(root_path)
      expect(flash.now[:success]).not_to be_nil
    end

    it 'returns error when the there is an exception' do
      stub_cognito_response(method: :verify_software_token, payload: Aws::CognitoIdentityProvider::Errors::CodeMismatchException.new(nil, nil))
      session[:email] = 'test@test.test'
      session[:access_token] = "valid-access-token"
      post :enrol, params: { mfa_enrolment_form: { code: 12345 }}
      expect(response).to have_http_status(:bad_request)
      expect(subject).to render_template(:index)
      expect(flash.now[:success]).to be_nil
      expect(flash.now[:error]).not_to be_nil
    end
  end
end
