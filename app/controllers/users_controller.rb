require 'auth/authentication_backend'

class UsersController < ApplicationController
  include AuthenticationBackend
  layout 'main_layout'

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
    flash[:error] = "User does not exist."
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
      @gds_team = Team.find_by_id(params[:team_id])&.name == TEAMS::GDS
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

  def as_team_member(cognito_user:)
    user = cognito_user.to_h
    user_id = user[:username]
    status = user[:user_status]
    attributes_key = user.key?(:user_attributes) ? :user_attributes : :attributes
    attributes = user[attributes_key].to_h { |attr| [attr[:name], attr[:value]] }
    given_name = attributes['given_name']
    family_name = attributes['family_name']
    email = attributes['email']
    roles = attributes['custom:roles'].split(%r{,\s*})
    TeamMember.new(user_id: user_id, given_name: given_name, family_name: family_name, email: email, roles: roles, status: status)
  end

  def setup_user_in_cognito
    add_user(
      email: @form.email,
      given_name: @form.given_name,
      family_name: @form.family_name,
      roles: @form.roles,
    )
  end

  def add_user_to_team_in_cognito(new_user, team)
    add_user_to_group(username: new_user.username, group: team.team_alias)
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
      @gds_team = team.name == TEAMS::GDS
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
