require 'rails_helper'

RSpec.describe ProfileController, type: :controller do
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
