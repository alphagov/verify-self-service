require 'auth/authentication_backend'

class UsersController < ApplicationController
  include AuthenticationBackend
  layout 'main_layout'

  def index
    @gds = current_user.permissions.team_management
    if @gds
      @teams = Team.all
    else
      @team = Team.find_by_id(current_user.team)
    end
  end

  def invite
    if current_user.permissions.admin_management
      @gds_team = Team.find_by_id(params[:team_id])&.name == TEAMS::GDS
    end
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
    if Team.exists?(params[:team_id])
      true
    else
      @form.errors.add(t('invite.error.team.missing'))
      false
    end
  end

  def setup_user_in_cognito
    add_user(
      email: @form.email,
      given_name: @form.given_name,
      family_name: @form.family_name,
      roles: @form.roles
    )
  end

  def add_user_to_team_in_cognito(new_user, team)
    add_user_to_group(username: new_user.username, group: team.name)
  end

  def invite_user
    begin
      team = Team.find(params[:team_id])
      invite = setup_user_in_cognito
    rescue AuthenticationBackend::UsernameExistsException => e
      flash.now[:errors] = t('users.invite.errors.already_exists')
    rescue AuthenticationBackend::AuthenticationBackendException => e
      flash.now[:errors] = t('users.invite.errors.generic_error')
    end

    begin
      add_user_to_team_in_cognito(invite.user, team) unless team.nil?
    rescue AuthenticationBackend::AuthenticationBackendException => e
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
end
