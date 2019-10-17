require 'rails_helper'

RSpec.describe ProfileController, type: :controller do
  include AuthSupport, CognitoSupport

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

    describe "GET #show" do
      it "renders the show page" do
        usermgr_stub_auth
        get :show
        expect(response).to have_http_status(:success)
        expect(subject).to render_template(:show)
      end
    end

    context 'running in test' do
      it "profile does not populate instance variables when in test" do
        usermgr_stub_auth
        get :show
        expect(@controller.instance_variable_get(:@using_stub)).to eq(nil)
      end
    end

    context 'running in production' do
      it "profile populates instance variables when in production" do
        Rails.env = 'production'
        usermgr_stub_auth
        get :show
        expect(@controller.instance_variable_get(:@using_stub)).to eq(nil)
      end
    end
    
    context 'running in development' do
      it "profile populates instance variables when in development" do
        Rails.env = 'development'
        usermgr_stub_auth
        get :show
        expect(@controller.instance_variable_get(:@using_stub)).to eq(true)
      end
    end
  end
end
