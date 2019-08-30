module AuthenticationBackend
  # Abstracted Exceptions
  # Aws::CognitoIdentityProvider::Errors::NotAuthorizedException,
  # Aws::CognitoIdentityProvider::Errors::UserNotFoundException,
  # Aws::CognitoIdentityProvider::Errors::InvalidParameterException,
  # Aws::CognitoIdentityProvider::Errors::CodeMismatchException
  # Aws::CognitoIdentityProvider::Errors::ServiceError
  # Aws::CognitoIdentityProvider::Errors::AliasExistsException,
  # Aws::CognitoIdentityProvider::Errors::UsernameExistsException => e
  # Aws::CognitoIdentityProvider::Errors::ResourceNotFoundException

  class NotAuthorizedException < StandardError; end
  class UserGroupNotFoundException < StandardError; end
  class AuthenticationBackendException < StandardError; end

  class AuthenticationResponse
    attr_reader :params, :id_token, :access_token

    def initialize(params:, cognito_response:)
      @params = params
      @id_token = cognito_response[:authentication_result][:id_token]
      @access_token = cognito_response[:authentication_result][:access_token]
    end
  end

  class ChallengeResponse
    attr_reader :client_id, :session_id, :challenge_name, :challenge_parameters

    def initialize(cognito_response:)
      @challenge_name = cognito_response[:challenge_name]
      @session_id = cognito_response[:session]
      @challenge_parameters = cognito_response[:challenge_parameters]
    end
  end

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

    raise AuthenticationBackendException("No Response Back from Authentication Service to process")
  end

private

  def process_response(cognito_response:, params:)
    if cognito_response.challenge_name.present?
      ChallengeResponse.new(cognito_response: cognito_response)
    else
      AuthenticationResponse.new(params: params, cognito_response: cognito_response)
    end
  end

  # Cognito Methods below this point

  # Returns an authentication response, a challenge response or an exception
  def initiate_auth(email:, password:)
    SelfService.service(:cognito_client).initiate_auth(
      client_id: cognito_client_id,
      auth_flow: 'USER_PASSWORD_AUTH',
      auth_parameters: {
        'USERNAME' => email,
        'PASSWORD' => password
      }
    )
  rescue Aws::CognitoIdentityProvider::Errors::NotAuthorizedException,
         Aws::CognitoIdentityProvider::Errors::UserNotFoundException => e
    raise NotAuthorizedException.new(e)
  rescue Aws::CognitoIdentityProvider::Errors::InvalidParameterException => e
    raise AuthenticationBackendException.new(e)
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
    SelfService.service(:cognito_client).respond_to_auth_challenge(
      client_id: cognito_client_id,
      session: params[:cognito_session_id],
      challenge_name: challenge_name,
      challenge_responses: challenge_responses
    )
  rescue Aws::CognitoIdentityProvider::Errors::InvalidParameterException,
         Aws::CognitoIdentityProvider::Errors::CodeMismatchException => e
    raise NotAuthorizedException.new(e)
  end

  def cognito_client_id
    Rails.configuration.cognito_client_id
  end
end
