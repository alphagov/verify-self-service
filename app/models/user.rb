class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  # Disabled modules
  # :registerable, :recoverable
  devise :database_authenticatable, :rememberable, :validatable
end
