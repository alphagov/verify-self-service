require_relative 'authentication_backend'

class ChallengeResponse
  attr_reader :response_type, :client_id, :session_id, :challenge_name, :challenge_parameters

  def initialize(cognito_response:)
    @response_type = AuthenticationBackend::CHALLENGE
    @challenge_name = cognito_response[:challenge_name]
    @session_id = cognito_response[:session]
    @challenge_parameters = cognito_response[:challenge_parameters]
  end
end
