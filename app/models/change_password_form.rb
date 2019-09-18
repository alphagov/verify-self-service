class ChangePasswordForm
  include ActiveModel::Model

  attr_accessor :old_password, :password, :password_confirmation

  validates_presence_of :old_password, :password, :password_confirmation
  validates_confirmation_of :password
  validates :password, length: { minimum: 8 }

  def initialize(params)
    @old_password = params[:old_password]
    @password = params[:password]
    @password_confirmation = params[:password_confirmation]
  end
end
