class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  # Disabled modules
  # :registerable, :recoverable
  if %w(test development).include? Rails.env
    # devise :database_authenticatable, :registerable,
    #      :recoverable, :rememberable, :validatable
    devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable
  else
    devise :database_authenticatable, :rememberable, :validatable
  end
end
