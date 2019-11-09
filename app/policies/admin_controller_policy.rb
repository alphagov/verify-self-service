class AdminControllerPolicy < ApplicationPolicy
  def index?
    user.permissions.admin_management
  end

  def publish_metadata?
    user.permissions.admin_management
  end
end
