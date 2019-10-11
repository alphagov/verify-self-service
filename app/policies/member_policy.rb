require 'auth/authentication_backend'
class MemberPolicy < ApplicationPolicy
  include AuthenticationBackend
  attr_reader :user, :object

  def initialize(user, object)
    @user = user
    @object = object
  end

  def member_authorized?
    return true if user.roles.include?('gds')

    team_member_of_user_manager? && not_updating_own_permissions
  end

  alias_method :show?, :member_authorized?
  alias_method :update?, :member_authorized?
  alias_method :resend_invitation?, :member_authorized?
  alias_method :show_update_email?, :member_authorized?
  alias_method :update_email?, :member_authorized?

private

  def team_member_of_user_manager?
    current_user_team_members = get_users_in_group(group_name: current_user_team_alias).map { |cognito_user| as_team_member(cognito_user: cognito_user) }
    members = current_user_team_members.collect(&:user_id)
    members.include? object.id
  end

  def current_user_team_alias
    Team.find(user.team).team_alias
  end

  def not_updating_own_permissions
    user.user_id != object.id
  end
end
