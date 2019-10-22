require_relative 'challenge_response'
require_relative 'authenticated_response'
require 'securerandom'

module AuthenticationBackend
  class NotAuthorizedException < StandardError; end
  class TemporaryPasswordExpiredException < StandardError; end
  class UserGroupNotFoundException < StandardError; end
  class AuthenticationBackendException < StandardError; end
  class UsernameExistsException < StandardError; end
  class GroupExistsException < StandardError; end
  class InvalidOldPasswordError < StandardError; end
  class InvalidNewPasswordException < StandardError; end
  class InvalidConfirmationCodeException < StandardError; end
  class ExpiredConfirmationCodeException < StandardError; end
  class UserNotFoundException < StandardError; end
  class UserNotConfirmedException < StandardError; end

  MINIMUM_PASSWORD_LENGTH = 12
  AUTHENTICATED = 'authenticated'.freeze
  CHALLENGE = 'challenge'.freeze
  RETRY = 'retry'.freeze
  OK = 'ok'.freeze

  # Authentication flows start here and will return either
  # an authentication response, a challenge response or an
  # exception.
  def authentication_flow(params)
    if params.key?(:cognito_session_id)
      resp = respond_to_challenge(params)
    else
      resp = initiate_auth(email: params[:email], password: params[:password])
    end
    return process_response(cognito_response: resp, params: params) if resp.present?

    raise AuthenticationBackendException.new("No Response Back from Authentication Service to process")
  end

  def request_password_reset(params)
    client.forgot_password(
      client_id: cognito_client_id,
      username: params[:email],
    )
  rescue Aws::CognitoIdentityProvider::Errors::NotAuthorizedException
    Rails.logger.error("User #{params[:email]} is not set up properly but is trying to reset their password")
  rescue Aws::CognitoIdentityProvider::Errors::UserNotFoundException
    Rails.logger.error("User #{params[:email]} is not present but is trying to reset their password")
  rescue Aws::CognitoIdentityProvider::Errors::LimitExceededException
    Rails.logger.error("User #{params[:email]} has made to many attempts to reset their password")
  rescue Aws::CognitoIdentityProvider::Errors::UserNotConfirmedException
    Rails.logger.error("User #{params[:email]} does not have a confirmed email to perform password reset")
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
    Rails.logger.error(e)
  end

  def reset_password(params)
    client.confirm_forgot_password(
      client_id: cognito_client_id,
      username: params[:email],
      confirmation_code: params[:code],
      password: params[:password],
      )
  rescue Aws::CognitoIdentityProvider::Errors::CodeMismatchException => e
    raise InvalidConfirmationCodeException.new(e)
  rescue Aws::CognitoIdentityProvider::Errors::InvalidPasswordException => e
    raise InvalidNewPasswordException.new(e)
  rescue Aws::CognitoIdentityProvider::Errors::ExpiredCodeException => e
    raise ExpiredConfirmationCodeException.new(e)
  rescue Aws::CognitoIdentityProvider::Errors::UserNotFoundException => e
    Rails.logger.error("User #{params[:email]} is not present but is trying to reset their password")
    raise UserNotFoundException.new(e)
  end

  def create_group(name:, description:)
    client.create_group(
      group_name: name,
      description: description,
      user_pool_id: user_pool_id,
    )
  rescue Aws::CognitoIdentityProvider::Errors::InvalidParameterException => e
    raise AuthenticationBackendException.new(e)
  rescue Aws::CognitoIdentityProvider::Errors::GroupExistsException => e
    raise GroupExistsException.new(e)
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
    raise AuthenticationBackendException.new(e)
  end

  def delete_group(name:)
    client.delete_group(
      group_name: name,
      user_pool_id: user_pool_id,
    )
  rescue Aws::CognitoIdentityProvider::Errors::ResourceNotFoundException
    Rails.logger.warn('The group does not exist/already been deleted')
    {}
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
    raise AuthenticationBackendException.new(e)
  end

  # Returns a secret shared code to associate a TOTP app/device with
  def associate_device(access_token:)
    associate = client.associate_software_token(access_token: access_token)
    associate.secret_code
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
    raise AuthenticationBackendException.new("Error occurred associating device with error #{e.message}")
  end

  def add_user(email:, given_name:, family_name:, roles:)
    client.admin_create_user(
      temporary_password: create_temporary_password,
      user_attributes: [
        {
          name: 'email',
          value: email,
        },
        {
          name: 'email_verified',
          value: 'True',
        },
        {
          name: 'given_name',
          value: given_name,
        },
        {
          name: 'family_name',
          value: family_name,
        },
        {
          name: 'custom:roles',
          value: roles.join(","),
        },
      ],
      username: email,
      user_pool_id: user_pool_id,
  )
  rescue Aws::CognitoIdentityProvider::Errors::AliasExistsException,
         Aws::CognitoIdentityProvider::Errors::UsernameExistsException => e
    raise UsernameExistsException.new(e)
  rescue StandardError => e
    raise AuthenticationBackendException.new(e)
  end

  def resend_invite(username:)
    client.admin_create_user(
      temporary_password: create_temporary_password,
      message_action: 'RESEND',
      username: username,
      user_pool_id: user_pool_id,
  )
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
    raise AuthenticationBackendException.new(e)
  end

  def add_user_to_group(username:, group:)
    client.admin_add_user_to_group(
      user_pool_id: user_pool_id,
      username: username,
      group_name: group,
    )
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
    raise AuthenticationBackendException.new(e)
  end

  def get_users(limit: 60)
    client.list_users(
      user_pool_id: user_pool_id,
      limit: limit,
    )
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
    raise AuthenticationBackendException.new(e)
  end

  def get_users_in_group(group_name:, limit: 60)
    client.list_users_in_group(user_pool_id: user_pool_id,
        group_name: group_name,
        limit: limit).users
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError
    []
  end

  def update_user_email(user_id:, email:)
    client.admin_update_user_attributes(
      user_pool_id: user_pool_id,
      username: user_id,
      user_attributes: [
        { name: "email", value: email },
        { name: 'email_verified', value: 'True' },
      ],
    )
  rescue Aws::CognitoIdentityProvider::Errors::AliasExistsException => e
    raise UsernameExistsException.new(e)
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
    raise AuthenticationBackendException.new(e)
  end

  def list_groups(limit: 60)
    client.list_groups(
      user_pool_id: user_pool_id,
      limit: limit,
    )
  end

  def get_user(user_id:)
    client.admin_get_user(user_pool_id: user_pool_id, username: user_id)
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
    raise AuthenticationBackendException.new(e.message)
  end

  def update_user_roles(user_id:, roles:)
    client.admin_update_user_attributes(
      user_pool_id: user_pool_id,
      username: user_id,
      user_attributes: [{ name: "custom:roles", value: roles.join(',') }],
    )
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
    raise AuthenticationBackendException.new(e.message)
  end

  def find_users_by_role(limit: 60, role:)
    users = get_users(limit: limit)
    users.users.select { |user|
      user.attributes.find { |att|
        att.name == 'custom:roles' && att.value.include?(role)
      }
    }
  end

  def get_group(group_name:)
    client.get_group(
      group_name: group_name,
      user_pool_id: user_pool_id,
    )
  rescue Aws::CognitoIdentityProvider::Errors::ResourceNotFoundException => e
    raise UserGroupNotFoundException.new(e)
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
    raise AuthenticationBackendException.new(e)
  end

  def authentication_backend_status
    client.describe_user_pool(user_pool_id: user_pool_id)
    OK
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
    raise AuthenticationBackendException.new(e)
  end

  def change_password(new_password:, current_password:, access_token:)
    client.change_password(
      previous_password: current_password,
      proposed_password: new_password,
      access_token: access_token,
    )
  rescue Aws::CognitoIdentityProvider::Errors::NotAuthorizedException => e
    raise InvalidOldPasswordError.new(e)
  rescue Aws::CognitoIdentityProvider::Errors::InvalidPasswordException => e
    raise InvalidNewPasswordException.new(e)
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
    Rails.logger.warn "An unknown cognito error occured with message: #{e}"
    raise AuthenticationBackendException.new(e)
  end

  def as_team_member(cognito_user:)
    user = cognito_user.to_h
    user_id = user[:username]
    status = user[:user_status]
    attributes_key = user.key?(:user_attributes) ? :user_attributes : :attributes
    attributes = user[attributes_key].to_h { |attr| [attr[:name], attr[:value]] }
    given_name = attributes['given_name']
    family_name = attributes['family_name']
    email = attributes['email']
    roles = attributes['custom:roles'].split(%r{,\s*})
    TeamMember.new(user_id: user_id, given_name: given_name, family_name: family_name, email: email, roles: roles, status: status)
  end

  def set_mfa_preferences(access_token:)
    client.set_user_mfa_preference(
      software_token_mfa_settings: {
        enabled: true,
        preferred_mfa: true,
      },
      access_token: access_token,
    )
    true
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError
    false
  end

  def get_user_info(access_token:)
    client.get_user(access_token: access_token)
  end

  def verify_code_for_mfa(access_token:, code:)
    client.verify_software_token(
      access_token: access_token,
      user_code: code,
    ).status
  rescue Aws::CognitoIdentityProvider::Errors::EnableSoftwareTokenMFAException => e
    raise InvalidConfirmationCodeException.new(e)
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
    raise AuthenticationBackendException.new(e)
  end

private

  def process_response(cognito_response:, params:)
    if cognito_response.challenge_name.present?
      create_challenge_response(cognito_response: cognito_response,
                                params: params)
    else
      AuthenticatedResponse.new(cognito_response: cognito_response,
                                params: params)
    end
  end

  # MFA Set up needs a secret code from cognito which updates the session
  # When we get this we massage the cognito response to give it the new
  # session token from AWS.
  def create_challenge_response(cognito_response:, params:)
    if cognito_response.challenge_name == 'MFA_SETUP'
      response_hash = setup_mfa_response(cognito_response: cognito_response, params: params)
    elsif cognito_response.challenge_name.include?('_RETRY')
      cognito_response.challenge_name = cognito_response.challenge_name.gsub('_RETRY', '')
      response_hash = cognito_response.to_h
    else
      response_hash = { email: params[:email], cognito_response: cognito_response }
    end

    ChallengeResponse.new(response_hash)
  end

  def setup_mfa_response(cognito_response:, params:)
    token_resp = client.associate_software_token(session: cognito_response.session)
    cognito_response.session = token_resp.session
    {
      email: params[:email],
      cognito_response: cognito_response,
      secret_code: token_resp.secret_code,
    }
  end

  # Cognito Methods below this point

  # Returns an authentication response, a challenge response or an exception
  def initiate_auth(email:, password:)
    client.initiate_auth(
      client_id: cognito_client_id,
      auth_flow: 'USER_PASSWORD_AUTH',
      auth_parameters: {
        'USERNAME' => email,
        'PASSWORD' => password,
      },
    )
  rescue Aws::CognitoIdentityProvider::Errors::NotAuthorizedException,
         Aws::CognitoIdentityProvider::Errors::UserNotFoundException => e
    if e.message == 'Temporary password has expired and must be reset by an administrator.'
      raise TemporaryPasswordExpiredException.new(e)
    else
      raise NotAuthorizedException.new(e)
    end
  rescue Aws::CognitoIdentityProvider::Errors::InvalidParameterException => e
    raise AuthenticationBackendException.new(e)
  end

  # Returns an authentication response normally with JWT
  def respond_to_challenge(params)
    challenge_name = params[:challenge_name]
    username = params[:challenge_parameters]['USER_ID_FOR_SRP'] || params[:email]
    challenge_responses = { "USERNAME": username }
    case challenge_name
    when 'NEW_PASSWORD_REQUIRED'
      challenge_responses.merge!("NEW_PASSWORD": params[:new_password])
      send_challenge(session: params[:cognito_session_id], challenge_name: challenge_name, challenge_responses: challenge_responses)
    when 'SMS_MFA', 'SOFTWARE_TOKEN_MFA'
      challenge_responses.merge!('SOFTWARE_TOKEN_MFA_CODE': params[:totp_code])
      send_challenge(session: params[:cognito_session_id], challenge_name: challenge_name, challenge_responses: challenge_responses)
    when 'MFA_SETUP'
      totp_resp = client.verify_software_token(session: params[:cognito_session_id], user_code: params[:totp_code])
      if totp_resp.status == 'SUCCESS'
        challenge_responses.merge!('ANSWER': 'SOFTWARE_TOKEN_MFA')
        resp = send_challenge(session: totp_resp.session, challenge_name: challenge_name, challenge_responses: challenge_responses)
        set_mfa_preferences(access_token: resp.authentication_result[:access_token]) unless resp.authentication_result[:access_token].nil?
        resp
      else
        raise AuthenticationBackendException.new("Unknown status returned by cognito when verifying software token.  Status returned: #{totp_resp.status}")
      end
    else
      raise AuthenticationBackendException.new("Unknown challenge_name returned by cognito.  Challenge name returned: #{challenge_name}")
    end
  rescue Aws::CognitoIdentityProvider::Errors::EnableSoftwareTokenMFAException,
         Aws::CognitoIdentityProvider::Errors::InvalidPasswordException => e
    response_hash = {
      type: RETRY,
      email: params[:email],
      secret_code: params[:secret_code],
      session_id: params[:cognito_session_id],
      challenge_name: "#{params[:challenge_name]}_RETRY",
      challenge_parameters: params[:challenge_parameters],
      flash_message: { code: e.code, message: e.message },
    }
    ChallengeResponse.new(response_hash)
  rescue Aws::CognitoIdentityProvider::Errors::InvalidParameterException,
         Aws::CognitoIdentityProvider::Errors::CodeMismatchException => e
    raise NotAuthorizedException.new(e)
  end

  def send_challenge(session:, challenge_name:, challenge_responses:)
    client.respond_to_auth_challenge(
      client_id: cognito_client_id,
      session: session,
      challenge_name: challenge_name,
      challenge_responses: challenge_responses,
    )
  end

  def client
    SelfService.service(:cognito_client)
  end

  def cognito_client_id
    Rails.configuration.cognito_client_id
  end

  def user_pool_id
    Rails.configuration.cognito_user_pool_id
  end

  def create_temporary_password
    temporary_password = ''
    until password_meets_criteria?(temporary_password) do
      temporary_password = generate_password
    end
    temporary_password
  end

  def generate_password
    SecureRandom.urlsafe_base64(12).insert(SecureRandom.random_number(11), SecureRandom.random_number(9).to_s)
  end

  def password_meets_criteria?(password)
    is_long_enough = password.length >= MINIMUM_PASSWORD_LENGTH
    has_uppercase = password =~ /[A-Z]/
    has_lowercase = password =~ /[a-z]/
    has_numbers = password =~ /[0-9]/

    is_long_enough && has_uppercase && has_lowercase && has_numbers
  end
end
