class UpdateUserEmailForm
  include ActiveModel::Model

  attr_reader :email
  validates_presence_of :email
  validates :email, email: true

  def initialize(params = {})
    @email = params[:email]
  end
end
