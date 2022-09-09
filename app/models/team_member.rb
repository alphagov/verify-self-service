class TeamMember
  attr_reader :user_id, :first_name, :last_name, :email, :roles, :status

  def initialize(user_id:, first_name:, last_name:, email:, roles:, status:)
    @user_id = user_id
    @email = email
    @first_name = first_name
    @last_name = last_name
    @roles = roles
    @status = status
  end

  def full_name
    "#{@first_name} #{@last_name}"
  end

  def cert_manager?
    @roles.include? ROLE::CERTIFICATE_MANAGER
  end

  def user_manager?
    @roles.include? ROLE::USER_MANAGER
  end

  def gds?
    @roles.include? ROLE::GDS
  end

  def user_status?(status)
    @status == status
  end
end
