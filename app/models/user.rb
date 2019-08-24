require_relative 'remote_authenticatable'

class User
  include ActiveModel::Serialization
  include ActiveModel::AttributeAssignment
  include ActiveModel::Validations #required because some before_validations are defined in devise
  extend ActiveModel::Callbacks #required to define callbacks
  extend Devise::Models

  # create getter and setter methods internally for the fields below
  attr_accessor :email, :access_token, :challenge_name, :cognito_session_id,
                :mfa, :challenge_parameters, :roles, :full_name, :family_name,
                :given_name, :phone_number, :user_id, :login_id, :password, :new_password,
                :totp_code, :permissions, :session_start_time, :team

  #required by Devise
  define_model_callbacks :validation

  devise :remote_authenticatable, :timeoutable

  # Latest devise tries to initialize this class with values
  # ignore it for now
  def initialize(options = {}); end

  def save!; end

  def attributes
    super.merge(roles: nil, permissions: nil)
  end

  def to_hash
    instance_variables.map { |var| [var.to_s.delete('@'), instance_variable_get(var)] }.to_h
  end
end
