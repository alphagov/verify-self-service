class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  # Disabled modules
  # :registerable, :recoverable
  if %w(test development).include? Rails.env
    # devise :database_authenticatable, :registerable,
    #      :recoverable, :rememberable, :validatable
    devise :database_authenticatable, :registerable, :validatable
  else
    devise :database_authenticatable, :validatable
  end
  attr_accessor :username, :email, :password, :password_confirmation, :remember_me, :totp_code, :cognito_session_id, :challenge_parameters
end
