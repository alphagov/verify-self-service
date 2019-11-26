require 'auth/authentication_backend'
require 'notify/notification'
require 'auth/temporary_password'

class UsersController < ApplicationController
  include Notification
  include AuthenticationBackend
  include TemporaryPassword
  layout 'main_layout'
  before_action :find_team_name

  def index
    @user = current_user
    @gds = current_user.permissions.admin_management

    if @gds
      if params['team_id']
        @team = Team.find_by_id(params['team_id'])
        @team_members = get_users_in_group(group_name: @team.team_alias).map { |cognito_user| as_team_member(cognito_user: cognito_user) }
      else
        @teams = Team.all
      end
    else
      @team = Team.find_by_id(current_user.team)
      @team_members = get_users_in_group(group_name: @team.team_alias).map { |cognito_user| as_team_member(cognito_user: cognito_user) }
    end
  end

  def show
    @gds = current_user.permissions.admin_management
    user_id = params['user_id']
    cognito_user = get_user(user_id: user_id)
    @team_member = as_team_member(cognito_user: cognito_user)
    @form = UpdateUserRolesForm.new(roles: @team_member.roles)
  rescue AuthenticationBackendException
    flash[:error] = t('users.errors.invalid_user')
    redirect_to users_path
  end

  def update
    @form = UpdateUserRolesForm.new(roles: params.dig('update_user_roles_form', 'roles'))
    user_id = params['user_id']
    if @form.valid?
      update_user_roles(user_id: user_id, roles: @form.roles)
      UserRolesUpdatedEvent.create(data:
                                     { user_id: user_id,
                                       roles: @form.roles.join(',') })
      redirect_to users_path
    else
      cognito_user = get_user(user_id: user_id)
      @team_member = as_team_member(cognito_user: cognito_user)
      @gds = current_user.permissions.admin_management
      flash.now[:errors] = @form.errors.full_messages.join(', ')
      render :show, status: :bad_request
    end
  rescue AuthenticationBackendException
    flash.now[:errors] = t 'devise.failure.unknown_cognito_error'
    render :show, status: :internal_server_error
  end

  def show_remove_user
    @user = as_team_member(cognito_user: get_user(user_id: params[:user_id]))
  end

  def remove_user
    begin
      @user = as_team_member(cognito_user: get_user(user_id: params[:user_id]))
      delete_user(username: @user.email)
      UserDeletedEvent.create(data: { username: @user.email, user_id: params[:user_id], name: @user.full_name })
    rescue AuthenticationBackend::AuthenticationBackendException
      flash[:errors] = t('users.remove_user.errors.generic_error')
    end
    redirect_to users_path
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
      @gds_team = Team.find_by_id(params[:team_id])&.name == TEAMS::GDS
      render :invite, status: :bad_request
    end
  end

  def resend_invitation
    begin
      user = as_team_member(cognito_user: get_user(user_id: params[:user_id]))
      @temporary_password = create_temporary_password

      resend_invite(username: user.email, temporary_password: @temporary_password)

      send_invite_email(user)
      flash[:success] = t('users.update.resend_invitation.success')
    rescue AuthenticationBackendException => e
      flash[:error] = t('users.update.resend_invitation.error')
      Rails.logger.error e
    end
    redirect_to update_user_path(user_id: params[:user_id])
  end

  def show_update_email
    @user = as_team_member(cognito_user: get_user(user_id: params[:user_id]))
    @form = UpdateUserEmailForm.new(email: @user.email)
  end

  def update_email
    @form = UpdateUserEmailForm.new(params[:update_user_email_form] || {})
    if @form.valid?
      update_user_email(user_id: params[:user_id], email: @form.email)
      UpdateUserEmailEvent.create(data: { user_id: params[:user_id], email: @form.email })
      redirect_to update_user_path
    else
      @user = as_team_member(cognito_user: get_user(user_id: params[:user_id]))
      render :show_update_email, status: :bad_request
    end
  rescue AuthenticationBackend::UsernameExistsException
    @user = as_team_member(cognito_user: get_user(user_id: params[:user_id]))
    @form.errors.add(:email, t('users.update_email.errors.already_exists', email: @form.email))
    render :show_update_email, status: :bad_request
  rescue AuthenticationBackend::AuthenticationBackendException
    @user = as_team_member(cognito_user: get_user(user_id: params[:user_id]))
    @form.errors.add(:base, t('users.update_email.errors.generic_error'))
    render :show_update_email, status: :bad_request
  end

  def show_reset_user_password
    @user = as_team_member(cognito_user: get_user(user_id: params[:user_id]))
  end

  def reset_user_password
    begin
      @user = as_team_member(cognito_user: get_user(user_id: params[:user_id]))
      admin_reset_user_password(username: @user.email)
      ResetUserPasswordEvent.create(data: { username: @user.email, user_id: params[:user_id], name: @user.full_name })
    rescue AuthenticationBackend::AuthenticationBackendException
      flash[:errors] = t('users.reset_user_password.errors.generic_error')
    end
    redirect_to users_path
  end

private

  def send_invite_email(user)
    send_invitation_email(
      email_address: user.email,
      first_name: user.first_name,
      temporary_password: @temporary_password,
     )
  end

  def team_valid?
    if Team.exists?(params[:team_id])
      true
    else
      @form.errors.add(:base, t('invite.error.team.missing'))
      false
    end
  end

  def find_team_name
    @team_name = Team.find_by_id(current_user.team).name unless current_user.team.nil?
  end

  def setup_user_in_cognito
    add_user(
      email: @form.email,
      given_name: @form.first_name,
      family_name: @form.last_name,
      roles: @form.roles,
      temporary_password: @temporary_password,
    )
  end

  def add_user_to_team_in_cognito(new_user, team)
    add_user_to_group(username: new_user.username, group: team.team_alias)
  end

  def invite_user
    begin
      team = Team.find(params[:team_id])
      @temporary_password = create_temporary_password
      invite = setup_user_in_cognito
      add_user_to_team_in_cognito(invite.user, team) unless team.nil?
      send_invite_email(@form)
    rescue AuthenticationBackend::UsernameExistsException => e
      flash[:errors] = t('users.invite.errors.already_exists')
    rescue AuthenticationBackend::AuthenticationBackendException => e
      Rails.logger.error e.message
      flash[:errors] = t('users.invite.errors.generic_error')
    end

    if e
      Rails.logger.error e
      @gds_team = team.name == TEAMS::GDS
      render :invite, status: :bad_request
    else
      UserInvitedEvent.create(data:
        { user_id: invite.user.username,
          roles: @form.roles.join(','),
          team_id: team.id,
          team_name: team.name })
      flash[:success] = t('users.invite.success')
      redirect_to users_path
    end
  end
end
