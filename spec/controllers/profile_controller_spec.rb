require 'rails_helper'

RSpec.describe ProfileController, type: :controller do
  include AuthSupport, CognitoSupport, NotifySupport

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

    it 'redirects to the profile page on success and sends email' do
      usermgr_stub_auth
      stub_notify_response
      expected_email_body = {
        email_address: @user.email,
        template_id: "029b2f45-72f2-4386-8149-71bf57ba86d1",
        personalisation: {
          first_name: @user.first_name,
        }
      }
      post :change_mfa, params: { mfa_enrolment_form: { 'totp_code': '123456' } }
      expect(response).to have_http_status(:redirect)
      expect(subject).to redirect_to(profile_path)
      expect(stub_notify_request(expected_email_body)).to have_been_made.once
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

  context '#update_user_name' do
    it 'renders the show user name page' do
      usermgr_stub_auth
      get :show_update_name
      expect(response).to have_http_status(:success)
      expect(subject).to render_template(:show_update_name)
    end
    
    it 'updates the user name and sends email' do
      usermgr_stub_auth
      stub_cognito_response(method: :update_user_attributes, payload: {} )
      stub_notify_response
      post :update_name, params: { update_user_name_form: { first_name: 'Joe', last_name: 'Bloggs' } }
      expected_email_body = {
        email_address: @user.email,
        template_id: "c6880583-6f8e-4820-bb2e-98125e355f72",
        personalisation: {
          new_name: "Joe Bloggs",
        }
      }

      expect(UpdateUserNameEvent.last.data['first_name']).to eq('Joe')
      expect(UpdateUserNameEvent.last.data['last_name']).to eq('Bloggs')
      expect(subject).to redirect_to(profile_path)
      expect(stub_notify_request(expected_email_body)).to have_been_made.once
    end

    it 'fails with error when form not valid' do
      usermgr_stub_auth
      stub_cognito_response(method: :update_user_attributes, payload: {})
      post :update_name, params: { update_user_name_form: { given_name: ''} }
      expect(response).to have_http_status(:bad_request)
      expect(subject).to render_template(:show_update_name)
    end

    it 'fails with error when a cognito error is thrown' do
      usermgr_stub_auth
      stub_cognito_response(method: :update_user_attributes, payload: 'Aws::CognitoIdentityProvider::Errors::ServiceError')
      post :update_name, params: { update_user_name_form: { first_name: 'Joe', last_name: 'Bloggs' } }
      expect(response).to have_http_status(:bad_request)
      expect(subject).to render_template(:show_update_name)
      expect(subject.instance_variable_get('@form').errors.full_messages_for(:base)).to include(t('users.update_name.errors.generic_error'))
    end
  end
end
