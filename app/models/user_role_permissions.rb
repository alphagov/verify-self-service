class UserRolePermissions
  attr_reader :component_management, :team_management, :user_management,
              :read_components, :update_profile, :change_password

  def initialize(roles_str, email)
    all_users
    roles = roles_str.nil? ? [] : roles_str.split(',').map(&:strip)
    user_manager if roles.include?(ROLE::USER_MANAGER)
    cert_manager if roles.include?(ROLE::CERTIFICATE_MANAGER)
    gds_user if roles.include?(ROLE::GDS) && email.ends_with?("@digital.cabinet-office.gov.uk")
  end

private

  def all_users
    @read_components = true
    @update_profile = true
    @change_password = true
    @component_management = false
    @team_management = false
    @user_management = false
  end

  def cert_manager
    @component_management = true
  end

  def user_manager
    @user_management = true
  end

  def gds_user
    @component_management = true
    @user_management = true
    @team_management = true
  end
end
