class MfaControllerPolicy < ApplicationPolicy
  attr_reader :user, :mfa_controller

  def initialize(user, mfa_controller)
    @user = user
    @mfa_controller = mfa_controller
  end

  def index?
    true
  end

  def enrol?
    true
  end
end
