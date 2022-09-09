class SignInForm
  include ActiveModel::Model

  attr_reader :email, :password

  validates_presence_of :email, :password
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }

  def initialize(params)
    @email = params[:email]&.downcase
    @password = params[:password]
  end
end
