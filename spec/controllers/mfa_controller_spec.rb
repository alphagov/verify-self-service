require 'rails_helper'

RSpec.describe MfaController, type: :controller do
  include AuthSupport

  describe '#index' do
    it 'renders the page when asked to enrol to MFA' do
      SelfService.service(:cognito_client).stub_responses(:associate_software_token, { secret_code: 'abcdefgh' })
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
      SelfService.service(:cognito_client).stub_responses(:verify_software_token, {})
      SelfService.service(:cognito_client).stub_responses(:set_user_mfa_preference, {})
      session[:email] = 'test@test.test'
      session[:access_token] = "valid-access-token"
      post :enrol, params: { mfa_enrolment_form: { code: 12345 }}
      expect(response).to have_http_status(:redirect)
      expect(subject).to redirect_to(root_path)
      expect(flash.now[:success]).not_to be_nil
    end

    it 'returns error when the there is an exception' do
      SelfService.service(:cognito_client).stub_responses(:verify_software_token, Aws::CognitoIdentityProvider::Errors::CodeMismatchException.new(nil, nil))
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
