class InviteUserForm
  include ActiveModel::Model

  attr_reader :email, :given_name, :family_name, :roles

  validates_presence_of :email, :given_name, :family_name, :roles

  validate :email_is_valid, :validate_roles

  def initialize(hash)
    @email = hash[:email]
    @given_name = hash[:given_name]
    @family_name = hash[:family_name]
    @roles = hash[:roles]
  end

private

  def email_is_valid
    errors.add(:email, "Invalid email format") unless EmailValidator.valid?(email, strict_mode: true)
  end

  def validate_roles
    valid_roles = [ROLE::CERTIFICATE_MANAGER, ROLE::USER_MANAGER, ROLE::GDS]
    if (invalid_roles = (roles.to_a - valid_roles))
      invalid_roles.each do |role|
        errors.add(:roles, role + " is not a valid role")
      end
    end
  end
end
