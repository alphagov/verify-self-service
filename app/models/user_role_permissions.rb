class UserRolePermissions
  attr_reader :admin_management, :component_management, :team_management, :user_management, :event_management,
              :certificate_management, :read_components, :update_profile, :change_password

  def initialize(roles_str, email)
    all_users
    roles = roles_str.nil? ? [] : roles_str.split(',').map(&:strip)
    user_manager if roles.include?(ROLE::USER_MANAGER)
    cert_manager if roles.include?(ROLE::CERTIFICATE_MANAGER)
    component_manager if roles.include?(ROLE::COMPONENT_MANAGER)
    gds_user if roles.include?(ROLE::GDS) && email.ends_with?(TEAMS::GDS_EMAIL_DOMAIN)
  end

  def to_s
    "read_components = #{read_components}\n" \
    "update_profile = #{update_profile}\n" \
    "change_password = #{change_password}\n" \
    "certificate_management = #{certificate_management}\n" \
    "component_management = #{component_management}\n" \
    "team_management = #{team_management}\n" \
    "user_management = #{user_management}\n" \
    "event_management = #{event_management}\n" \
    "admin_management = #{admin_management}"
  end

  def to_hash
    instance_variables.map { |var| [var.to_s.delete('@'), instance_variable_get(var)] }.to_h
  end

private

  def all_users
    @read_components = true
    @update_profile = true
    @change_password = true
    @certificate_management = false
    @component_management = false
    @team_management = false
    @user_management = false
    @event_management = false
  end

  def cert_manager
    @certificate_management = true
  end

  def component_manager
    @certificate_management = true
    @component_management = true
  end

  def user_manager
    @user_management = true
  end

  def gds_user
    @event_management = true
    @component_management = true
    @certificate_management = true
    @user_management = true
    @team_management = true
    @admin_management = true
  end
end
