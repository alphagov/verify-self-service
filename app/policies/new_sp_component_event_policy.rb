class NewSpComponentEventPolicy < ApplicationPolicy
  attr_reader :user, :sp_component

  def initialize(user, sp_component)
    @user = user
    @sp_component = sp_component
  end

  def new?
    user.permissions.component_management
  end

  def create?
    user.permissions.component_management
  end
end
