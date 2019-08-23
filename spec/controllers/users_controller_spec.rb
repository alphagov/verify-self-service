require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  include AuthSupport

  before(:each) do
    gdsuser_stub_auth
  end

  describe '#index' do
    it 'renders the page' do
      get :index, :params => { :team_id => 0 }
      expect(response).to have_http_status(:success)
      expect(subject).to render_template(:index)
    end
  end

  describe '#invite' do
    it 'renders the invite page' do
      get :invite, :params => { :team_id => 0 }
      expect(response).to have_http_status(:success)
      expect(subject).to render_template(:invite)
    end
  end

  describe '#new' do
    it 'invites the user when all valid' do
      Rails.configuration.cognito_user_pool_id = "dummy"
      SelfService.service(:cognito_client).stub_responses(:admin_create_user, { user: { username:'test@test.test' } })
      post :new, params: {
        team_id: 0,
        invite_user_form:
          {
            email: 'test@test.test',
            given_name: 'First Name',
            family_name: 'Surname',
            roles: [ROLE::USER_MANAGER, ROLE::CERTIFICATE_MANAGER]
          }
      }
      expect(response).to have_http_status(:redirect)
      expect(subject).to redirect_to(users_path)
      expect(flash.now[:errors]).to be_nil
      expect(flash.now[:success]).not_to be_nil
    end

    it 'fails to invite user when form params missing' do
      post :new, :params => { :team_id => 0 }
      expect(response).to have_http_status(:bad_request)
      expect(flash.now[:errors]).not_to be_nil
    end
  end
end
