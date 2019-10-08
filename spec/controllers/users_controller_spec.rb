require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  include AuthSupport, CognitoSupport

  let(:user_id) { SecureRandom::uuid }

  let(:cognito_users) {
    {:users => [
        {username: user_id,
         attributes: [{name: "given_name", value: "Cherry"},
                          {name: "family_name", value: "One"},
                          {name: "email", value: "cherry.one@test.com"},
                          {name: "custom:roles", value: "certmgr"}
         ]}]}
  }

  let(:cognito_user) {
    { username: user_id,
      user_attributes: [{name: "given_name", value: "Cherry"},
                        {name: "family_name", value: "One"},
                        {name: "email", value: "cherry.one@test.com"},
                        {name: "custom:roles", value: "certmgr"}]}
  }


  context 'GDS User' do
    before(:each) do
      gdsuser_stub_auth
    end

    describe '#index' do


      it 'renders the page' do
        get :index
        expect(response).to have_http_status(:success)
        expect(subject).to render_template(:index)
      end

      it 'renders the page when team specified' do
        team = FactoryBot.create(:team)
        stub_cognito_response(method: :list_users_in_group, payload: cognito_users)

        expect(subject).to receive(:as_team_member)

        get :index, :params => { :team_id => team.id }
        expect(subject).to render_template(:index)
        expect(response).to have_http_status(:success)
      end

    end

    describe '#show' do

      it 'renders the update user page' do
        stub_cognito_response(method: :admin_get_user, payload: cognito_user)

        expect(subject).to receive(:as_team_member).and_call_original

        get :show, :params => { :user_id => user_id }

        expect(response).to have_http_status(:success)
        expect(subject).to render_template(:show)
      end

      it 'redirects to all teams page when user_id is not found' do
        stub_cognito_response(method: :admin_get_user, payload: 'Aws::CognitoIdentityProvider::Errors::ServiceError')
        get :show, :params => { :user_id => user_id }
        expect(flash[:error]).to eq("User does not exist.")
        expect(response).to have_http_status(:redirect)
        expect(subject).to redirect_to(users_path)
      end
    end

    describe '#update' do
      it 'updates the user roles' do
        post :update, :params => { :update_user_roles_form => { :roles => [ROLE::CERTIFICATE_MANAGER]}, :user_id => user_id}
        expect(subject).to redirect_to(users_path)
      end

      it 'displays an error when validation fails' do
        stub_cognito_response(method: :admin_get_user, payload: cognito_user)
        post :update, :params => { :update_user_roles_form => { :roles => []}, :user_id => user_id}
        expect(subject).to render_template(:show)
        expect(response).to have_http_status(:bad_request)
      end

      it 'displays an error when authentication backend returns an error' do
        stub_cognito_response(method: :admin_update_user_attributes, payload: 'Aws::CognitoIdentityProvider::Errors::ServiceError')
        post :update, :params => { :update_user_roles_form => { :roles => [ROLE::CERTIFICATE_MANAGER]}, :user_id => user_id}
        expect(subject).to render_template(:show)
        expect(response).to have_http_status(:internal_server_error)
        expect(flash[:errors]).to eq(t 'devise.failure.unknown_cognito_error')
      end
    end

    describe '#show_update_email' do
      it 'renders the update email page' do
        get :show_update_email, :params => { :user_id => user_id }

        expect(response).to have_http_status(:success)
        expect(subject).to render_template(:show_update_email)
      end
    end

    describe '#update_email' do
      it 'updates the user email address' do
        post :update_email, :params => { :update_user_email_form => { :email => "test@test1.com"}, :user_id => user_id}
        expect(response).to have_http_status(:success)

        # TODO expect(subject).to redirect_to(update_user_path)
      end
    end

    describe '#invite' do
      it 'renders the invite page' do
        get :invite, :params => { :team_id => @user.team }
        expect(response).to have_http_status(:success)
        expect(subject).to render_template(:invite)
      end
    end

    describe '#new' do
      it 'invites the user when all valid' do
        Rails.configuration.cognito_user_pool_id = 'dummy'
        stub_cognito_response(method: :admin_create_user, payload: { user: { username:'test@test.test' } })
        team = FactoryBot.create(:team)
        post :new, params: {
          team_id: team.id,
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

  context 'User Manager' do
    before(:each) do
      usermgr_stub_auth
    end

    describe '#index' do
      it 'renders the page when team is matching' do
        get :index, :params => { :team_id => @user.team }
        expect(response).to have_http_status(:success)
        expect(subject).to render_template(:index)
      end
    end

    describe '#show' do

      it 'renders the update user page' do
        stub_cognito_response(method: :admin_get_user, payload: cognito_user)

        expect(subject).to receive(:as_team_member).and_call_original

        get :show, :params => { :user_id => user_id }

        expect(response).to have_http_status(:success)
        expect(subject).to render_template(:show)
      end

      it 'redirects to all teams page when user_id is not found' do
        stub_cognito_response(method: :admin_get_user, payload: 'Aws::CognitoIdentityProvider::Errors::ServiceError')
        get :show, :params => { :user_id => user_id }
        expect(flash[:error]).to eq("User does not exist.")
        expect(response).to have_http_status(:redirect)
        expect(subject).to redirect_to(users_path)
      end
    end

    describe '#update' do
      it 'updates the user roles' do
        stub_cognito_response(method: :admin_update_user_attributes, payload: {})
        post :update, :params => { :update_user_roles_form => { :roles => [ROLE::CERTIFICATE_MANAGER]}, :user_id => user_id}
        expect(subject).to redirect_to(users_path)
      end

      it 'displays an error when validation fails' do
        stub_cognito_response(method: :admin_get_user, payload: cognito_user)
        post :update, :params => { :update_user_roles_form => { :roles => []}, :user_id => user_id}
        expect(subject).to render_template(:show)
        expect(response).to have_http_status(:bad_request)
      end

      it 'displays an error when authentication backend returns an error' do
        stub_cognito_response(method: :admin_update_user_attributes, payload: 'Aws::CognitoIdentityProvider::Errors::ServiceError')
        post :update, :params => { :update_user_roles_form => { :roles => [ROLE::CERTIFICATE_MANAGER]}, :user_id => user_id}
        expect(subject).to render_template(:show)
        expect(response).to have_http_status(:internal_server_error)
        expect(flash[:errors]).to eq(t 'devise.failure.unknown_cognito_error')
      end
    end


    describe '#invite' do
      it 'renders the invite page when team is matching' do
        get :invite, :params => { :team_id => @user.team }
        expect(response).to have_http_status(:success)
        expect(subject).to render_template(:invite)
      end

      it 'does not render the invite page when team is not matching' do
        foreign_team = FactoryBot.create(:team, id: SecureRandom.uuid)
        get :invite, :params => { :team_id => foreign_team.id }
        expect(response).to_not have_http_status(:success)
        expect(subject).to_not render_template(:invite)
        expect(response).to have_http_status(:forbidden)
        expect(flash[:warn]).to eq t('shared.errors.authorisation')
      end
    end

    describe '#new' do
      it 'invites the user when all valid' do
        Rails.configuration.cognito_user_pool_id = "dummy"
        stub_cognito_response(method: :admin_create_user, payload: { user: { username:'test@test.test' } })

        post :new, params: {
          team_id: @user.team,
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

      it 'fails to invite user when inviting to a foreign team' do
        foreign_team = FactoryBot.create(:team, id: SecureRandom.uuid)
        post :new, params: {
          team_id: foreign_team.id,
          invite_user_form:
            {
              email: 'test@test.test',
              given_name: 'First Name',
              family_name: 'Surname',
              roles: [ROLE::USER_MANAGER, ROLE::CERTIFICATE_MANAGER]
            }
        }
        expect(response).to have_http_status(:forbidden)
        expect(flash[:warn]).to eq t('shared.errors.authorisation')
      end
    end
  end
end
