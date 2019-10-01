require 'rails_helper'

RSpec.describe PasswordController, type: :controller do
  include AuthSupport, CognitoSupport

  context 'changing passwords' do
    it 'advises password changed when successful' do
      usermgr_stub_auth
      post :update_password, params: { change_password_form: { 'old_password': 'oldPassword1', 'password': 'newPassword1', 'password_confirmation': 'newPassword1' } }
      expect(subject).to redirect_to(profile_path)
      expect(flash.now[:error]).to be_nil
      expect(flash.now[:notice]).to eq(t('password.password_changed'))
    end

    it 'errors when password does not meet acceptence criteria' do
      usermgr_stub_auth
      stub_cognito_response(
        method: :change_password,
        payload: "InvalidPasswordException"
      )
      post :update_password, params: { change_password_form: { 'old_password': 'oldPassword1', 'password': 'newpassword', 'password_confirmation': 'newpassword' } }
      expect(response).to have_http_status(:bad_request)
      expect(flash.now[:error]).to eq(t('devise.sessions.InvalidPasswordException'))
    end

    it 'errors when old password is wrong' do
      usermgr_stub_auth
      stub_cognito_response(
        method: :change_password,
        payload: "NotAuthorizedException"
      )
      post :update_password, params: { change_password_form: { 'old_password': 'wrong_password', 'password': 'newpassword', 'password_confirmation': 'newpassword' } }
      expect(response).to have_http_status(:bad_request)
      expect(flash.now[:error]).to eq(t('password.errors.old_password_mismatch'))
    end
  end

  context 'requesting password reset' do
    it 'sends code to user if form valid' do
      post :send_code, params: { forgotten_password_form: { 'email': 'test@test.com' } }
      expect(response).to have_http_status(:success)
      expect(subject).to render_template(:user_code)
    end

    it 'renders the user_code page on TooManyAttemptsError' do
      stub_cognito_response(
        method: :forgot_password,
        payload: 'LimitExceededException'
      )
      email = 'test@test.com'
      expect(Rails.logger).to receive(:error).with("User #{email} has made to many attempts to reset their password")
      post :send_code, params: { forgotten_password_form: { 'email': email } }
      expect(response).to have_http_status(:success)
      expect(subject).to render_template(:user_code)
    end

    it 'renders the user_code page on UserBadStateError' do
      stub_cognito_response(
        method: :forgot_password,
        payload: 'NotAuthorizedException'
      )
      email = 'test@test.com'
      expect(Rails.logger).to receive(:error).with("User #{email} is not set up properly but is trying to reset their password")
      post :send_code, params: { forgotten_password_form: { 'email': email } }
      expect(response).to have_http_status(:success)
      expect(subject).to render_template(:user_code)
    end

    it 'renders the user_code page on UserGroupNotFoundException' do
      stub_cognito_response(
        method: :forgot_password,
        payload: 'UserNotFoundException'
      )
      email = 'test@test.com'
      expect(Rails.logger).to receive(:error).with("User #{email} is not present but is trying to reset their password")
      post :send_code, params: { forgotten_password_form: { 'email': email } }
      expect(response).to have_http_status(:success)
      expect(subject).to render_template(:user_code)
    end
  end

  context 'resetting password' do
    it 'user redirected to new session with success message' do
      post :process_code, params: { password_recovery_form: { 'email': 'test@test.com', 'code': '123456', 'password': 'password', 'password_confirmation': 'password' } }
      expect(response).to have_http_status(:redirect)
      expect(subject).to redirect_to(new_user_session_path)
      expect(flash[:notice]).to include(I18n.t('password.password_recovered'))
    end

    it 'user redirected to new session with no message on CodeMismatchException' do
      stub_cognito_response(
        method: :confirm_forgot_password,
        payload: 'CodeMismatchException'
      )
      post :process_code, params: { password_recovery_form: { 'email': 'test@test.com', 'code': '000000', 'password': 'password', 'password_confirmation': 'password' } }
      expect(response).to have_http_status(:redirect)
      expect(subject).to redirect_to(new_user_session_path)
      expect(flash[:notice]).to be_nil
    end

    it 'user redirected to new session with no message on UserNotFoundException' do
      stub_cognito_response(
        method: :confirm_forgot_password,
        payload: 'UserNotFoundException'
      )
      expect(Rails.logger).to receive(:error).with("User test@test.com is not present but is trying to reset their password")
      post :process_code, params: { password_recovery_form: { 'email': 'test@test.com', 'code': '000000', 'password': 'password', 'password_confirmation': 'password' } }
      expect(response).to have_http_status(:redirect)
      expect(subject).to redirect_to(new_user_session_path)
      expect(flash[:notice]).to be_nil
    end
  end
end
