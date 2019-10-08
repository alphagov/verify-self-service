class UsersControllerPolicy < ApplicationPolicy
  attr_reader :user, :event

  def initialize(user, event)
    @user = user
    @event = event
  end

  def index?
    user.permissions.user_management
  end

  def invite?
    user.permissions.user_management
  end

  def update?
    user.permissions.user_management
  end

  def show?
    user.permissions.user_management
  end

  def new?
    user.permissions.user_management
  end

  def show_update_email?
    user.permissions.user_management
  end

  def update_email?
    user.permissions.user_management
  end
end
