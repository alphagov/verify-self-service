class InviteUserForm
  include ActiveModel::Model

  attr_reader :email, :first_name, :last_name, :roles

  validates_presence_of :email, :first_name, :last_name, :roles

  validate :email_is_valid, :validate_roles

  def initialize(hash)
    @email = hash[:email]
    @first_name = hash[:first_name]
    @last_name = hash[:last_name]
    @roles = hash[:roles]
  end

private

  def email_is_valid
    if roles&.include?(ROLE::GDS) && !email.ends_with?(TEAMS::GDS_EMAIL_DOMAIN)
      errors.add(:email, I18n.t('users.invite.errors.invalid_gds_email'))
    end

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
