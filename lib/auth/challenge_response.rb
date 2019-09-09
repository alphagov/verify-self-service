require_relative 'authentication_backend'

class ChallengeResponse
  attr_reader :response_type, :client_id, :session_id, :challenge_parameters, :secret_code
  attr_accessor :challenge_name

  def initialize(cognito_response: nil, secret_code: nil, challenge_name: nil, session: nil, challenge_parameters: nil)
    @response_type = AuthenticationBackend::CHALLENGE
    if cognito_response.nil?
      @challenge_name = challenge_name
      @session_id = session
      @secret_code = secret_code
      @challenge_parameters = challenge_parameters
    else
      @challenge_name = cognito_response[:challenge_name]
      @session_id = cognito_response[:session]
      @secret_code = secret_code
      @challenge_parameters = cognito_response[:challenge_parameters]
    end
  end
end
