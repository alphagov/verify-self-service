class UpdateUserRolesForm
  include ActiveModel::Model

  attr_reader :roles

  validates_presence_of :roles

  validate :validate_roles

  def initialize(roles:)
    @roles = roles
  end

private

  def validate_roles
    valid_roles = [ROLE::CERTIFICATE_MANAGER, ROLE::USER_MANAGER, ROLE::GDS]
    if (invalid_roles = (roles.to_a - valid_roles))
      invalid_roles.each do |role|
        errors.add(:roles, role + " is not a valid role")
      end
    end
  end
end
