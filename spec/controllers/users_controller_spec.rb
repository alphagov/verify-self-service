require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  include AuthSupport

  before(:each) do
    user_stub_auth
  end

  describe '#index' do
    it 'renders the page' do
      get :index
      expect(response).to have_http_status(:success)
      expect(subject).to render_template(:index)
    end
  end

  describe '#invite' do
    it 'renders the invite page' do
      get :invite
      expect(response).to have_http_status(:success)
      expect(subject).to render_template(:invite)
    end
  end

  describe '#new' do
    it 'invites the user when all valid' do
      Rails.application.secrets.cognito_user_pool_id = "dummy"
      SelfService.service(:cognito_client).stub_responses(:admin_create_user, { user: { username:'test@test.test' } })
      post :new, params: { 
        invite_user_form: 
          { 
            email: 'test@test.test', 
            given_name: 'First Name', 
            family_name: 'Surname', 
            mfa: 'SOFTWARE_TOKEN_MFA',
            roles: [ROLE::USER_MANAGER, ROLE::CERTIFICATE_MANAGER]
          }
      }
      expect(response).to have_http_status(:success)
      expect(flash.now[:errors]).to be_nil
      expect(flash.now[:success]).not_to be_nil
    end

    it 'fails to invite user when params missing' do
      post :new
      expect(response).to have_http_status(:bad_request)
      expect(flash.now[:errors]).not_to be_nil
    end
  end
end
