class EventPolicy < ApplicationPolicy
  attr_reader :user, :component

  def initialize(user, component)
    @user = user
    @component = component
  end

  def index?
    user.permissions.event_managemnt
  end
end
