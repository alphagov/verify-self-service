class NewMsaComponentEventPolicy < ApplicationPolicy
  attr_reader :user, :msa_component

  def initialize(user, msa_component)
    @user = user
    @msa_component = msa_component
  end

  def new?
    user.permissions.component_management
  end

  def create?
    user.permissions.component_management
  end
end
