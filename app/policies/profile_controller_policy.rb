class ProfileControllerPolicy < ApplicationPolicy
  def show?
    true
  end

  def change_password?
    true
  end

  def switch_client?
    return false unless Rails.env.development?

    true
  end

  def update_role?
    return false unless Rails.env.development?

    true
  end
end
