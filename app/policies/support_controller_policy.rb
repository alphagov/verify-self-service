class SupportControllerPolicy < ApplicationPolicy
  attr_reader :user

  def index?
    user.permissions.view_support
  end
end
