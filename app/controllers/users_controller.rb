class UsersController < ApplicationController
  layout "main_layout"

  def index
    @user = current_user
    @gds = current_user.permissions.team_management
    if @gds
      @teams = Team.all
    else
      @team = current_user.team
    end
  end

  def invite
    @form = InviteUserForm.new({})
  end

  def new
    @form = InviteUserForm.new(params['invite_user_form'] || {})
    if @form.valid? && team_valid?
      invite_user
    else
      flash.now[:errors] = @form.errors.full_messages.join(', ')
      render :invite, status: :bad_request
    end
  end

private

  def team_valid?
    if Team.exists?(params[:team_id]) || params[:team_id] == '0'
      true
    else
      @form.errors.add(t('invite.error.team.missing'))
      false
    end
  end

  def setup_user_in_cognito
    temporary_password = ('a'..'z').to_a.sample(3) + ('A'..'Z').to_a.sample(3) + ('0'..'9').to_a.sample(3) + ('!'..'/').to_a.sample(1)
    SelfService.service(:cognito_client).admin_create_user(
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
      user_pool_id: user_pool_id
      )
  end

  def add_user_to_team_in_cognito(new_user, team)
    SelfService.service(:cognito_client).admin_add_user_to_group(
      user_pool_id: user_pool_id,
      username: new_user.username,
      group_name: team.name
    )
  end

  def invite_user
    begin
      if params[:team_id] != '0'
        team = Team.find(params[:team_id])
      else
        team = Team.new(id: 0, name: 'gds')
      end
      invite = setup_user_in_cognito
    rescue Aws::CognitoIdentityProvider::Errors::AliasExistsException,
           Aws::CognitoIdentityProvider::Errors::UsernameExistsException => e
      flash.now[:errors] = t('users.invite.errors.already_exists')
    rescue StandardError => e
      flash.now[:errors] = t('users.invite.errors.generic_error')
    end

    begin
      add_user_to_team_in_cognito(invite.user, team) unless team.nil?
    rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
      flash.now[:errors] = t('users.invite.errors.generic_error')
    end

    if e
      Rails.logger.error e
      render :invite, status: :bad_request
    else
      UserInvitedEvent.create(data:
        { user_id: invite.user.username,
          roles: @form.roles.join(','),
          team_id: team.id,
          team_name: team.name })
      flash.now[:success] = t('users.invite.success')
      redirect_to users_path
    end
  end

  def user_pool_id
    Rails.application.secrets.cognito_user_pool_id
  end
end
