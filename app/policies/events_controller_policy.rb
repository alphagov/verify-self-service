class EventsControllerPolicy < ApplicationPolicy
  attr_reader :user, :component

  def initialize(user, component)
    super
    @user = user
    @component = component
  end

  def index?
    user.permissions.event_management
  end
end
