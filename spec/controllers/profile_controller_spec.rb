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

  context 'setup mfa' do
    it 'returns to profile if mfa is already setup' do
      usermgr_stub_auth
      get :setup_mfa
      expect(response).to have_http_status(:redirect)
      expect(subject).to redirect_to(profile_path)
    end

    it 'redirects to change mfa when cognito returns an error' do
      usermgr_stub_auth
      stub_cognito_response(
        method: :set_user_mfa_preference,
        payload: 'ServiceError',
      )
      get :setup_mfa
      expect(response).to have_http_status(:redirect)
      expect(subject).to redirect_to(profile_update_mfa_path)
    end
  end

  context 'change_mfa' do
    it 'renders the page again if form is not valid' do
      usermgr_stub_auth
      post :change_mfa, params: { mfa_enrolment_form: { 'totp_code': nil } }
      expect(response).to have_http_status(:bad_request)
      expect(subject).to render_template(:show_change_mfa)
    end

    it 'renders the page again if params is missing' do
      usermgr_stub_auth
      post :change_mfa
      expect(response).to have_http_status(:bad_request)
      expect(subject).to render_template(:show_change_mfa)
    end

    it 'redirects to the profile page on success' do
      usermgr_stub_auth
      post :change_mfa, params: { mfa_enrolment_form: { 'totp_code': '123456' } }
      expect(response).to have_http_status(:redirect)
      expect(subject).to redirect_to(profile_path)
    end

    it 'renders the page again on code mismatch' do
      usermgr_stub_auth
      stub_cognito_response(
        method: :verify_software_token,
        payload: 'EnableSoftwareTokenMFAException',
      )
      post :change_mfa, params: { mfa_enrolment_form: { 'totp_code': '123456' } }
      expect(response).to have_http_status(:bad_request)
      expect(subject).to render_template(:show_change_mfa)
    end
  end
end
