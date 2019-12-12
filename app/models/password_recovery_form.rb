class PasswordRecoveryForm
  include ActiveModel::Model

  attr_reader :code, :password, :password_confirmation
  attr_accessor :email

  validates_presence_of :code, :email, :password, :password_confirmation
  validates_confirmation_of :password
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }

  def initialize(params = {})
    @code = params[:code]
    @email = params[:email]&.downcase
    @password = params[:password]
    @password_confirmation = params[:password_confirmation]
  end

  def to_h
    instance_variables.map { |var| [var.to_s.delete('@').to_sym, instance_variable_get(var)] }.to_h
  end
end
