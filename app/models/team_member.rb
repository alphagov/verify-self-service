class TeamMember
  attr_accessor :user_id, :given_name, :family_name, :email, :roles

  def initialize(user_id:, given_name:, family_name:, email:, roles:)
    @user_id = user_id
    @email = email
    @given_name = given_name
    @family_name = family_name
    @roles = roles
  end

  def full_name
    @given_name + " " + @family_name
  end

  def cert_manager?
    @roles.include? ROLE::CERTIFICATE_MANAGER
  end

  def user_manager?
    @roles.include? ROLE::USER_MANAGER
  end
end
