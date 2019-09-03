require_relative 'challenge_response'
require_relative 'authenticated_response'

module AuthenticationBackend
  class NotAuthorizedException < StandardError; end
  class UserGroupNotFoundException < StandardError; end
  class AuthenticationBackendException < StandardError; end
  class UsernameExistsException < StandardError; end
  class GroupExistsException < StandardError; end

  AUTHENTICATED = 'authenticated'.freeze
  CHALLENGE = 'challenge'.freeze

  # Authenticaiton flows start here and will return either
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

  def create_group(name:, description:)
    client.create_group(
      group_name: name,
      description: description,
      user_pool_id: user_pool_id
    )
  rescue Aws::CognitoIdentityProvider::Errors::InvalidParameterException => e
    raise AuthenticationBackendException.new(e.message)
  rescue Aws::CognitoIdentityProvider::Errors::GroupExistsException => e
    raise GroupExistsException.new(e.message)
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
    raise AuthenticationBackendException.new(e.message)
  end

  # Returns a secret shared code to associate a TOTP app/device with
  def associate_device(access_token:)
    associate = client.associate_software_token(access_token: access_token)
    associate.secret_code
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
    raise AuthenticationBackendException.new("Error occurred associating device with error #{e.message}")
  end

  def enrole_totp_device(access_token:, totp_code:)
    client.verify_software_token(
      access_token: access_token,
      user_code: totp_code
    )
    client.set_user_mfa_preference(
      access_token: access_token,
      software_token_mfa_settings: {
        enabled: true,
        preferred_mfa: true
      }
    )
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
    raise AuthenticationBackendException.new(e.message)
  end

  def add_user(email:, given_name:, family_name:, roles:, phone_number: nil)
    temporary_password = ('a'..'z').to_a.sample(3) + ('A'..'Z').to_a.sample(3) + ('0'..'9').to_a.sample(3) + ('!'..'/').to_a.sample(1)
    client.admin_create_user(
      temporary_password: temporary_password.join(''),
      user_attributes: [
        {
          name: 'email',
          value: email
        },
        {
          name: 'given_name',
          value: given_name
        },
        {
          name: 'family_name',
          value: family_name
        },
        {
          name: 'phone_number',
          value: phone_number
        },
        {
          name: 'custom:roles',
          value: roles.join(",")
        }
      ],
      username: email,
      user_pool_id: user_pool_id
  )
  rescue Aws::CognitoIdentityProvider::Errors::AliasExistsException,
         Aws::CognitoIdentityProvider::Errors::UsernameExistsException => e
    raise UsernameExistsException.new(e.message)
  rescue StandardError => e
    raise AuthenticationBackendException.new(e.message)
  end

  def add_user_to_group(username:, group:)
    client.admin_add_user_to_group(
      user_pool_id: user_pool_id,
      username: username,
      group_name: group
    )
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
    raise AuthenticationBackendException.new(e.message)
  end

  def get_users(limit: 50)
    client.list_users(
      user_pool_id: user_pool_id,
      limit: limit
    )
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
    raise AuthenticationBackendException.new(e.message)
  end

  def find_users_by_role(limit: 50, role:)
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
      user_pool_id: user_pool_id
    )
  rescue Aws::CognitoIdentityProvider::Errors::ResourceNotFoundException => e
    raise UserGroupNotFoundException.new(e.message)
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
    raise AuthenticationBackendException.new(e.message)
  end

  def status
    client.describe_user_pool(user_pool_id: user_pool_id)
    OK
  rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
    raise AuthenticationBackendException.new(e.message)
  end

private

  def process_response(cognito_response:, params:)
    if cognito_response.challenge_name.present?
      ChallengeResponse.new(cognito_response: cognito_response)
    else
      AuthenticatedResponse.new(params: params, cognito_response: cognito_response)
    end
  end

  # Cognito Methods below this point

  # Returns an authentication response, a challenge response or an exception
  def initiate_auth(email:, password:)
    client.initiate_auth(
      client_id: cognito_client_id,
      auth_flow: 'USER_PASSWORD_AUTH',
      auth_parameters: {
        'USERNAME' => email,
        'PASSWORD' => password
      }
    )
  rescue Aws::CognitoIdentityProvider::Errors::NotAuthorizedException,
         Aws::CognitoIdentityProvider::Errors::UserNotFoundException => e
    raise NotAuthorizedException.new(e.message)
  rescue Aws::CognitoIdentityProvider::Errors::InvalidParameterException => e
    raise AuthenticationBackendException.new(e.message)
  end

  # Returns an authentication response
  def respond_to_challenge(params)
    challenge_name = params[:challenge_name]
    case challenge_name
    when 'NEW_PASSWORD_REQUIRED'
      challenge_responses = {
        "USERNAME": params[:challenge_parameters]['USER_ID_FOR_SRP'],
        "NEW_PASSWORD": params[:new_password]
      }
    when 'SOFTWARE_TOKEN_MFA'
      challenge_responses = {
        "USERNAME": params[:challenge_parameters]['USER_ID_FOR_SRP'],
        "SOFTWARE_TOKEN_MFA_CODE": params[:totp_code]
      }
    else
      raise AuthenticationBackendException.new("Unknown challenge_name returned by cognito.  Challenge name returned: #{challenge_name}")
    end
    client.respond_to_auth_challenge(
      client_id: cognito_client_id,
      session: params[:cognito_session_id],
      challenge_name: challenge_name,
      challenge_responses: challenge_responses
    )
  rescue Aws::CognitoIdentityProvider::Errors::InvalidParameterException,
         Aws::CognitoIdentityProvider::Errors::CodeMismatchException => e
    raise NotAuthorizedException.new(e.message)
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
end
