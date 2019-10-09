class UpdateUserEmailForm
  include ActiveModel::Model

  attr_reader :email
  validates_presence_of :email
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  def initialize(params = {})
    @email = params[:email]
  end
end
