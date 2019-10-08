class UpdateUserEmailForm
  include ActiveModel::Model

  attr_reader :email
  validates_presence_of :email
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  def initialize(options = {})
    @email = options["update_user_email_form"]["email"] unless options.empty?
  end
end
  
