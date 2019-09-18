require 'rails_helper'

RSpec.describe ProfileController, type: :controller do
  include AuthSupport, CognitoSupport

  after(:each) do
    Rails.env = 'test'
  end

  describe "Profile Controller" do
    context 'logging in' do
      it "redirect to login if no user" do
        get :show
        expect(response.status).to eq(302)
      end

      it "get profile if have user" do
        usermgr_stub_auth
        get :show
        expect(response.status).to eq(200)
      end
    end

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

    context 'running in test' do
      it "profile does not populate instance variables when in test" do
        usermgr_stub_auth
        get :show
        expect(@controller.instance_variable_get(:@stub_available)).to eq(nil)
        expect(@controller.instance_variable_get(:@breakerofchains)).to eq(nil)
        expect(@controller.instance_variable_get(:@using_stub)).to eq(nil)
      end
    end

    context 'running in production' do
      it "profile populates instance variables when in production" do
        Rails.env = 'production'
        usermgr_stub_auth
        get :show
        expect(@controller.instance_variable_get(:@stub_available)).to eq(nil)
        expect(@controller.instance_variable_get(:@breakerofchains)).to eq(nil)
        expect(@controller.instance_variable_get(:@using_stub)).to eq(nil)
      end
    end
    
    context 'running in development' do
      it "profile populates instance variables when in development" do
        Rails.env = 'development'
        usermgr_stub_auth
        get :show
        expect(@controller.instance_variable_get(:@stub_available)).to eq(true)
        expect(@controller.instance_variable_get(:@breakerofchains)).to eq(false)
        expect(@controller.instance_variable_get(:@using_stub)).to eq(true)
      end
    end
  end
end
