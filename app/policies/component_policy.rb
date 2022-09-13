class ComponentPolicy < ApplicationPolicy
  attr_reader :user, :component, :msa_component, :sp_component

  def initialize(user, component)
    super
    @user = user
    @component = component
    @msa_component = component
    @sp_component = component
  end

  def index?
    user.permissions.component_management
  end

  def new?
    user.permissions.component_management
  end

  def show?
    user.permissions.certificate_management
  end

  def create?
    user.permissions.component_management
  end

  def edit?
    user.permissions.component_management
  end

  def update?
    user.permissions.component_management
  end

  def destroy?
    user.permissions.component_management
  end

  def associate_service?
    user.permissions.component_management
  end
end
