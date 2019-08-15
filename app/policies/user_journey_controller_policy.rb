class UserJourneyControllerPolicy < ApplicationPolicy
  attr_reader :user, :certificate

  def initialize(user, certificate)
    @user = user
    @certificate = certificate
  end

  def index?
    user.permissions.certificate_management
  end

  def before_you_start?
    user.permissions.certificate_management
  end

  def view_certificate?
    user.permissions.certificate_management
  end

  def upload_certificate?
    user.permissions.certificate_management
  end

  def upload_certificate_post?
    user.permissions.certificate_management
  end

  def check_your_certificate?
    user.permissions.certificate_management
  end

  def check_your_certificate_post?
    user.permissions.certificate_management
  end

  def confirmation?
    user.permissions.certificate_management
  end

  def confirmation_post?
    user.permissions.certificate_management
  end
end
