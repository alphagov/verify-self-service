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
    errors.add(:email, I18n.t('users.invite.errors.invalid_email')) unless EmailValidator.valid?(email, strict_mode: true)
  end

  def validate_roles
    valid_roles = [ROLE::CERTIFICATE_MANAGER, ROLE::USER_MANAGER, ROLE::GDS]
    if (invalid_roles = (roles.to_a - valid_roles))
      invalid_roles.each do |role|
        errors.add(:roles, I18n.t('users.invite.errors.invalid_role', role: role))
      end
    end
  end
end
