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
end
