class ProfileControllerPolicy < ApplicationPolicy
  def show?
    true
  end

  def password_form?
    true
  end

  def update_password?
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

  def setup_mfa?
    true
  end

  def show_change_mfa?
    true
  end

  def change_mfa?
    true
  end

  def request_new_code?
    true
  end

  def warn_mfa?
    true
  end

  def show_update_name?
    true
  end

  def update_name?
    true
  end
end
