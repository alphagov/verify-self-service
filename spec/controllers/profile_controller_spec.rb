require 'rails_helper'

RSpec.describe ProfileController, type: :controller do
  include CognitoSupport

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
        @request.env["devise.mapping"] = Devise.mappings[:user]
        user = FactoryBot.create(:user_manager_user)
        allow(request.env['warden']).to receive(:authenticate!).and_return(@user)
        allow(controller).to receive(:current_user).and_return(@user)
        sign_in user
        get :show
        expect(response.status).to eq(200)
      end
    end

    context 'changing passwords' do
      it 'errors when new passwords dont match' do
        @request.env["devise.mapping"] = Devise.mappings[:user]
        @user = FactoryBot.create(:user_manager_user)
        allow(request.env['warden']).to receive(:authenticate!).and_return(@user)
        allow(controller).to receive(:current_user).and_return(@user)
        sign_in @user
        post :change_password, params: { password_change: { 'new_password1': 'wrong', 'new_password2': 'right' } }
        expect(subject).to redirect_to(profile_path)
        expect(flash.now[:error]).not_to be_nil
        expect(flash.now[:error]).to eq(t('profile.password_mismatch'))
      end

      it 'advises password changed when successful' do
        @request.env["devise.mapping"] = Devise.mappings[:user]
        @user = FactoryBot.create(:user_manager_user)
        allow(request.env['warden']).to receive(:authenticate!).and_return(@user)
        allow(controller).to receive(:current_user).and_return(@user)
        sign_in @user
        post :change_password, params: { password_change: { 'old_password': 'oldPassword1', 'new_password1': 'newPassword1', 'new_password2': 'newPassword1' } }
        expect(subject).to redirect_to(profile_path)
        expect(flash.now[:error]).to be_nil
        expect(flash.now[:notice]).not_to be_nil
        expect(flash.now[:notice]).to eq(t('profile.password_changed'))
      end

      it 'errors when password does not meet acceptence criteria' do
        @request.env["devise.mapping"] = Devise.mappings[:user]
        @user = FactoryBot.create(:user_manager_user)
        allow(request.env['warden']).to receive(:authenticate!).and_return(@user)
        allow(controller).to receive(:current_user).and_return(@user)
        sign_in @user
        stub_cognito_response(
          method: :change_password,
          payload: "InvalidPasswordException"
        )
        post :change_password, params: { password_change: { 'old_password': 'oldPassword1', 'new_password1': 'newpassword', 'new_password2': 'newpassword' } }
        expect(subject).to redirect_to(profile_path)
        expect(flash.now[:error]).not_to be_nil
        expect(flash.now[:error]).to eq(t('devise.sessions.InvalidPasswordException'))
      end

      it 'errors when old password is wrong' do
        @request.env["devise.mapping"] = Devise.mappings[:user]
        @user = FactoryBot.create(:user_manager_user)
        allow(request.env['warden']).to receive(:authenticate!).and_return(@user)
        allow(controller).to receive(:current_user).and_return(@user)
        sign_in @user
        stub_cognito_response(
          method: :change_password,
          payload: "NotAuthorizedException"
        )
        post :change_password, params: { password_change: { 'old_password': 'wrong_password', 'new_password1': 'newpassword', 'new_password2': 'newpassword' } }
        expect(subject).to redirect_to(profile_path)
        expect(flash.now[:error]).not_to be_nil
        expect(flash.now[:error]).to eq(t('profile.old_password_mismatch'))
      end
    end

    context 'running in test' do
      it "profile does not populate instance variables when in test" do
        @request.env["devise.mapping"] = Devise.mappings[:user]
        @user = FactoryBot.create(:user_manager_user)
        allow(request.env['warden']).to receive(:authenticate!).and_return(@user)
        allow(controller).to receive(:current_user).and_return(@user)
        sign_in @user
        get :show
        expect(@controller.instance_variable_get(:@stub_available)).to eq(nil)
        expect(@controller.instance_variable_get(:@breakerofchains)).to eq(nil)
        expect(@controller.instance_variable_get(:@using_stub)).to eq(nil)
      end
    end

    context 'running in production' do
      it "profile populates instance variables when in production" do
        Rails.env = 'production'
        @request.env["devise.mapping"] = Devise.mappings[:user]
        @user = FactoryBot.create(:user_manager_user)
        allow(request.env['warden']).to receive(:authenticate!).and_return(@user)
        allow(controller).to receive(:current_user).and_return(@user)
        sign_in @user
        get :show
        expect(@controller.instance_variable_get(:@stub_available)).to eq(nil)
        expect(@controller.instance_variable_get(:@breakerofchains)).to eq(nil)
        expect(@controller.instance_variable_get(:@using_stub)).to eq(nil)
      end
    end
    
    context 'running in development' do
      it "profile populates instance variables when in development" do
        Rails.env = 'development'
        @request.env["devise.mapping"] = Devise.mappings[:user]
        @user = FactoryBot.create(:user_manager_user)
        allow(request.env['warden']).to receive(:authenticate!).and_return(@user)
        allow(controller).to receive(:current_user).and_return(@user)
        sign_in @user
        get :show
        expect(@controller.instance_variable_get(:@stub_available)).to eq(true)
        expect(@controller.instance_variable_get(:@breakerofchains)).to eq(false)
        expect(@controller.instance_variable_get(:@using_stub)).to eq(true)
      end
    end
  end
end
