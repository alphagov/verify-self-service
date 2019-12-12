class ForgottenPasswordForm
  include ActiveModel::Model

  attr_reader :email
  validates_presence_of :email
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  def initialize(params = {})
    @email = params[:email]&.downcase
  end

  def to_h
    instance_variables.map { |var| [var.to_s.delete('@').to_sym, instance_variable_get(var)] }.to_h
  end
end
