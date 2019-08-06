require 'securerandom'

class UsersController < ApplicationController
  layout "main_layout"

  def index; end

  def invite
    @form = InviteUserForm.new({})
  end

  def new
    @form = InviteUserForm.new(params['invite_user_form'] || {})
    if @form.valid?
      begin
        temporary_password = SecureRandom.alphanumeric(8) + ('!'..'/').to_a.sample
        invite = SelfService.service(:cognito_client).admin_create_user(
          temporary_password: temporary_password,
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
        #TODO: Add team, mfa ... to the event
        UserInvitedEvent.create(data: { user_id: invite.user.username, roles: @form.roles.join(",") }) if invite.dig(:user, :username)

        #TODO: Enroll user to MFA
      rescue Aws::CognitoIdentityProvider::Errors::AliasExistsException,
             Aws::CognitoIdentityProvider::Errors::UsernameExistsException => e
        flash.now[:errors] = t('users.invite.errors.already_exists')
      rescue StandardError => e
        flash.now[:errors] = t('users.invite.errors.generic_error')
      end
      Rails.logger.error e if e
      flash.now[:success] = t('users.invite.success') unless e
      render :invite
    else
      flash.now[:errors] = @form.errors.full_messages.join(', ')
      render :invite, status: :bad_request
    end
  end
end
