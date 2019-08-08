class UsersController < ApplicationController
  layout "main_layout"

  def index; end

  def invite
    @form = InviteUserForm.new({})
  end

  def new
    @form = InviteUserForm.new(params['invite_user_form'] || {})
    if @form.valid?
      invite_user
    else
      flash.now[:errors] = @form.errors.full_messages.join(', ')
      render :invite, status: :bad_request
    end
  end

private

  def invite_user
    temporary_password = ('a'..'z').to_a.sample(3) + ('A'..'Z').to_a.sample(3) + ('0'..'9').to_a.sample(3) + ('!'..'/').to_a.sample(1)
    begin
      invite = SelfService.service(:cognito_client).admin_create_user(
        temporary_password: temporary_password.join(''),
        user_attributes: [
          {
            name: 'email',
            value: @form.email
          },
          {
            name: 'given_name',
            value: @form.given_name
          },
          {
            name: 'family_name',
            value: @form.family_name
          },
          {
            name: 'custom:roles',
            value: @form.roles.join(",")
          }
        ],
        username: @form.email,
        user_pool_id: Rails.application.secrets.cognito_user_pool_id
      )
    rescue Aws::CognitoIdentityProvider::Errors::AliasExistsException,
           Aws::CognitoIdentityProvider::Errors::UsernameExistsException => e
      flash.now[:errors] = t('users.invite.errors.already_exists')
    rescue StandardError => e
      flash.now[:errors] = t('users.invite.errors.generic_error')
    end

    if e
      Rails.logger.error e
      render :invite, status: :bad_request
    else
      UserInvitedEvent.create(data: { user_id: invite.user.username, roles: @form.roles.join(",") })
      flash.now[:success] = t('users.invite.success')
      redirect_to users_path
    end
  end
end
