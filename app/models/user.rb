require_relative 'remote_authenticatable'

class User
  include ActiveModel::Validations #required because some before_validations are defined in devise
  extend ActiveModel::Callbacks #required to define callbacks
  extend Devise::Models

  # create getter and setter methods internally for the fields below
  attr_accessor :email, :access_token, :challenge_name, :cognito_session_id, :challenge_parameters,
                :organisation, :roles, :full_name, :family_name, :given_name, :phone_number,
                :user_id, :login_id, :password

  #required by Devise
  define_model_callbacks :validation

  devise :remote_authenticatable, :timeoutable

  # Latest devise tries to initialize this class with values
  # ignore it for now
  def initialize(options = {}); end

  def save!; end
end
