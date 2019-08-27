class GroupPolicy < ApplicationPolicy
  attr_reader :user, :object

  def initialize(user, object)
    @user = user
    @object = object
  end

  def team_authorized?
    check_membership(@user, @object.id)
  end

  alias_method :index?, :team_authorized?
  alias_method :show?, :team_authorized?
  alias_method :create?, :team_authorized?
  alias_method :update?, :team_authorized?
  alias_method :destroy?, :team_authorized?
  alias_method :invite?, :team_authorized?

private

  def check_membership(user, object_id)
    return true if user.roles.include?('gds')

    object_id == user&.team
  end
end
