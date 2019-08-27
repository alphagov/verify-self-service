class AdminControllerPolicy < ApplicationPolicy
  def index?
    user.permissions.admin_management
  end
end
