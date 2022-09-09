class CertificatesControllerPolicy < ApplicationPolicy
  attr_reader :user, :certificate

  def initialize(user, certificate)
    super
    @user = user
    @certificate = certificate
  end

  def new?
    user.permissions.certificate_management
  end

  def show?
    user.permissions.certificate_management
  end

  def create?
    user.permissions.certificate_management
  end

  def enable?
    user.permissions.certificate_management
  end

  def disable?
    user.permissions.certificate_management
  end

  def replace?
    user.permissions.certificate_management
  end
end
