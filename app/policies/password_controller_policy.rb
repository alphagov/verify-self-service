class PasswordControllerPolicy < ApplicationPolicy
  attr_reader :user, :email

  def initialize(user, email)
    super
    @user = user
    @email = email
  end

  def password_form?
    true
  end

  def update_password?
    true
  end

  def forgot_form?
    true
  end

  def send_code?
    true
  end

  def user_code?
    true
  end

  def process_code?
    true
  end

  def reset?
    true
  end

  def force_user_reset_password?
    true
  end
end
