class ComponentPolicy < ApplicationPolicy
  attr_reader :user, :component

  def initialize(user, component)
    @user = user
    @component = component
  end

  def create?
    user.permissions.component_management
  end
end
