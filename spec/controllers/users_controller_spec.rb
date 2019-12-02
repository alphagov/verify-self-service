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
        expect(flash[:error]).to eq(t('users.errors.invalid_user'))
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
        allow_any_instance_of(TemporaryPassword).to receive(:create_temporary_password).and_return("uyy-QN6ZUqy4MXnvd")

        stub_request(:post, "https://api.notifications.service.gov.uk/v2/notifications/email").
        with(
          body: "{\"email_address\":\"test@test.test\",\"template_id\":\"afdb4827-0f71-4588-b35d-80bd514f5bdb\",\"personalisation\":{\"first_name\":\"First Name\",\"url\":\"http://www.test.com\",\"temporary_password\":\"uyy-QN6ZUqy4MXnvd\"}}",
        ).to_return(status: 200, body: "{}", headers: {})

        post :new, params: {
          team_id: team.id,
          invite_user_form:
            {
              email: 'test@test.test',
              first_name: 'First Name',
              last_name: 'Surname',
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
        expect(assigns(:form).errors).not_to be_nil
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
        stub_cognito_response(method: :admin_update_user_attributes, payload: {})
        post :update_email, :params => { update_user_email_form: { email: 'test1@test.com'}, user_id: user_id }
        expect(UpdateUserEmailEvent.last.data["email"]).to eq('test1@test.com')
        expect(UpdateUserEmailEvent.last.data["user_id"]).to eq(user_id)
        expect(subject).to redirect_to(update_user_path)
      end

      it 'fails with error when form not valid' do
        stub_cognito_response(method: :admin_update_user_attributes, payload: {})
        post :update_email, :params => { update_user_email_form: { email: ''}, user_id: user_id}
        expect(response).to have_http_status(:bad_request)
        expect(subject).to render_template(:show_update_email)
      end

      it 'fails with error when email is not valid' do
        stub_cognito_response(method: :admin_get_user, payload: cognito_user)
        post :update_email, :params => { update_user_email_form: { email: ''}, user_id: user_id}
        expect(response).to have_http_status(:bad_request)
        expect(subject).to render_template(:show_update_email)
        expect(subject.instance_variable_get('@form').errors.full_messages).to include("Email can't be blank")
      end

      it 'fails with error when the form is not valid' do
        post :update_email, :params => { update_user_email_form: { blah: 'blah'}, user_id: user_id}
        expect(response).to have_http_status(:bad_request)
        expect(subject).to render_template(:show_update_email)
        expect(subject.instance_variable_get('@form').errors.full_messages).to include('Email is invalid')
      end

      it 'fails with error when form is missing' do
        post :update_email, :params => { user_id: user_id}
        expect(response).to have_http_status(:bad_request)
        expect(subject).to render_template(:show_update_email)
        expect(subject.instance_variable_get('@form').errors.full_messages).to include('Email is invalid')
      end

      it 'fails with error when email already exists' do
        stub_cognito_response(method: :admin_update_user_attributes, payload: 'AliasExistsException')
        post :update_email, :params => { update_user_email_form: { email: 'test@test.com'}, user_id: user_id}
        expect(response).to have_http_status(:bad_request)
        expect(subject).to render_template(:show_update_email)
        expect(subject.instance_variable_get('@form').errors.full_messages_for(:email)).to include('Email ' + t('users.update_email.errors.already_exists', email: 'test@test.com'))
      end

      it 'fails with error when a cognito error is thrown' do
        stub_cognito_response(method: :admin_update_user_attributes, payload: 'ServiceError')
        post :update_email, :params => { update_user_email_form: { email: 'test@test.com'}, user_id: user_id}
        expect(response).to have_http_status(:bad_request)
        expect(subject).to render_template(:show_update_email)
        expect(subject.instance_variable_get('@form').errors.full_messages_for(:base)).to include(t('users.update_email.errors.generic_error'))
      end
    end

    describe '#show_remove_user' do
      it 'renders the remove user page' do
        get :show_remove_user, params: { user_id: user_id }
        expect(response).to have_http_status(:success)
        expect(subject).to render_template(:show_remove_user)
      end
    end

    describe '#remove_user' do
      it 'removes the user' do
        stub_cognito_response(method: :admin_delete_user, payload: {} )
        delete :remove_user, params: { user_id: user_id }
        expect(UserDeletedEvent.last.data["username"]).to eq('cherry.one@test.com')
        expect(subject).to redirect_to(users_path)
      end

      it 'fails with error when a cognito error is thrown' do
        stub_cognito_response(method: :admin_delete_user, payload: 'Aws::CognitoIdentityProvider::Errors::ServiceError')
        delete :remove_user, params: { user_id: user_id }
        expect(response).to have_http_status(:redirect)
        expect(flash[:errors]).to eq(t 'users.remove_user.errors.generic_error')
        expect(subject).to redirect_to(users_path)
      end
    end

    describe '#show_reset_user_password' do
      it 'renders the reset user password page' do
        get :show_reset_user_password, params: { user_id: user_id }
        expect(response).to have_http_status(:success)
        expect(subject).to render_template(:show_reset_user_password)
      end
    end

    describe '#reset_user_password' do
      it 'resets the users password' do
        stub_cognito_response(method: :admin_reset_user_password, payload: {} )
        post :reset_user_password, params: { user_id: user_id }
        expect(ResetUserPasswordEvent.last.data["username"]).to eq('cherry.one@test.com')
        expect(subject).to redirect_to(users_path)
      end

      it 'fails with error when a cognito error is thrown' do
        stub_cognito_response(method: :admin_reset_user_password, payload: 'Aws::CognitoIdentityProvider::Errors::ServiceError')
        delete :reset_user_password, params: { user_id: user_id }
        expect(response).to have_http_status(:redirect)
        expect(flash[:errors]).to eq(t 'users.reset_user_password.errors.generic_error')
        expect(subject).to redirect_to(users_path)
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
        stub_cognito_response(method: :list_users_in_group, payload: cognito_users)

        expect(subject).to receive(:as_team_member).and_call_original

        get :show, :params => { :user_id => user_id }

        expect(response).to have_http_status(:success)
        expect(subject).to render_template(:show)
      end


      it 'redirects to all teams page when user_id is not found' do
        stub_cognito_response(method: :admin_get_user, payload: 'Aws::CognitoIdentityProvider::Errors::ServiceError')
        stub_cognito_response(method: :list_users_in_group, payload: cognito_users)
        get :show, :params => { :user_id => user_id }
        expect(flash[:error]).to eq(t('users.errors.invalid_user'))
        expect(response).to have_http_status(:redirect)
        expect(subject).to redirect_to(users_path)
      end
    end

    describe '#update' do
      it 'updates the user roles' do
        stub_cognito_response(method: :admin_update_user_attributes, payload: {})
        stub_cognito_response(method: :list_users_in_group, payload: cognito_users)
        post :update, :params => { :update_user_roles_form => { :roles => [ROLE::CERTIFICATE_MANAGER]}, :user_id => user_id}
        expect(subject).to redirect_to(users_path)
      end

      it 'displays an error when validation fails' do
        stub_cognito_response(method: :admin_get_user, payload: cognito_user)
        stub_cognito_response(method: :list_users_in_group, payload: cognito_users)
        post :update, :params => { :update_user_roles_form => { :roles => []}, :user_id => user_id}
        expect(subject).to render_template(:show)
        expect(response).to have_http_status(:bad_request)
      end

      it 'displays an error when authentication backend returns an error' do
        stub_cognito_response(method: :admin_update_user_attributes, payload: 'Aws::CognitoIdentityProvider::Errors::ServiceError')
        stub_cognito_response(method: :list_users_in_group, payload: cognito_users)
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
        allow_any_instance_of(TemporaryPassword).to receive(:create_temporary_password).and_return("uyy-QN6ZUqy4MXnvd")

        stub_request(:post, "https://api.notifications.service.gov.uk/v2/notifications/email").
        with(
          body: "{\"email_address\":\"test@test.test\",\"template_id\":\"afdb4827-0f71-4588-b35d-80bd514f5bdb\",\"personalisation\":{\"first_name\":\"First Name\",\"url\":\"http://www.test.com\",\"temporary_password\":\"uyy-QN6ZUqy4MXnvd\"}}"
        ).to_return(status: 200, body: "{}")

        post :new, params: {
          team_id: @user.team,
          invite_user_form:
            {
              email: 'test@test.test',
              first_name: 'First Name',
              last_name: 'Surname',
              roles: [ROLE::USER_MANAGER, ROLE::CERTIFICATE_MANAGER]
            }
        }
        expect(response).to have_http_status(:redirect)
        expect(subject).to redirect_to(users_path)
        expect(flash.now[:errors]).to be_nil
        expect(flash.now[:success]).not_to be_nil
      end

      it 'doesnt throw syntax error when a user fails to be invited' do
        Rails.configuration.cognito_user_pool_id = "dummy"
        stub_cognito_response(method: :admin_create_user, payload: 'AliasExistsException')

        post :new, params: {
          team_id: @user.team,
          invite_user_form:
            {
              email: 'test@test.test',
              first_name: 'First Name',
              last_name: 'Surname',
              roles: [ROLE::USER_MANAGER, ROLE::CERTIFICATE_MANAGER]
            }
        }
        expect(response).to have_http_status(:bad_request)
        expect(subject).to render_template(:invite)
        expect(flash.now[:errors]).to eq(t('users.invite.errors.already_exists'))
        expect(flash.now[:success]).to be_nil
      end

      it 'fails to invite user when inviting to a foreign team' do
        foreign_team = FactoryBot.create(:team, id: SecureRandom.uuid)
        post :new, params: {
          team_id: foreign_team.id,
          invite_user_form:
            {
              email: 'test@test.test',
              first_name: 'First Name',
              last_name: 'Surname',
              roles: [ROLE::USER_MANAGER, ROLE::CERTIFICATE_MANAGER]
            }
        }
        expect(response).to have_http_status(:forbidden)
        expect(flash[:warn]).to eq t('shared.errors.authorisation')
      end
    end

    describe '#resend_invitation' do
      it 'resends the invitation successfully' do
        stub_cognito_response(method: :admin_get_user, payload: cognito_user)
        stub_cognito_response(method: :list_users_in_group, payload: cognito_users)
        expect_any_instance_of(AuthenticationBackend).to receive(:resend_invite)
        allow_any_instance_of(TemporaryPassword).to receive(:create_temporary_password).and_return("uyy-QN6ZUqy4MXnvd")
        stub_request(:post, "https://api.notifications.service.gov.uk/v2/notifications/email").
        with(
          body: "{\"email_address\":\"cherry.one@test.com\",\"template_id\":\"afdb4827-0f71-4588-b35d-80bd514f5bdb\",\"personalisation\":{\"first_name\":\"Cherry\",\"url\":\"http://www.test.com\",\"temporary_password\":\"uyy-QN6ZUqy4MXnvd\"}}"
        ).to_return(status: 200, body: "{}")

        get :resend_invitation, params: { user_id: user_id }
        expect(subject).to redirect_to(update_user_path(user_id: user_id))
        expect(flash[:error]).to be_nil
        expect(flash[:success]).to eq(t('users.update.resend_invitation.success'))
      end

      it 'displays an error when it fails' do
        stub_cognito_response(method: :admin_get_user, payload: cognito_user)
        stub_cognito_response(method: :list_users_in_group, payload: cognito_users)
        stub_cognito_response(method: :admin_set_user_password, payload: 'Aws::CognitoIdentityProvider::Errors::ServiceError')
        get :resend_invitation, params: { user_id: user_id}
        expect(subject).to redirect_to(update_user_path(user_id: user_id))
        expect(flash[:error]).to eq(t('users.update.resend_invitation.error'))
        expect(flash[:success]).to be_nil
      end
    end
  end
end
