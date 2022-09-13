class TeamsControllerPolicy < ApplicationPolicy
  attr_reader :user, :team_controller

  def initialize(user, team_controller)
    super
    @user = user
    @team_controller = team_controller
  end

  def index?
    user.permissions.team_management
  end

  def show?
    user.permissions.team_management
  end

  def new?
    user.permissions.team_management
  end

  def create?
    user.permissions.team_management
  end

  def destroy?
    user.permissions.team_management
  end
end
