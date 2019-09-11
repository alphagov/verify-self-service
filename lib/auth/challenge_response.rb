require_relative 'authentication_backend'

class ChallengeResponse
  attr_reader :email, :response_type, :client_id, :session_id,
              :challenge_parameters, :secret_code, :flash_message
  attr_accessor :challenge_name

  def initialize(response_hash)
    @response_type = response_hash[:type] || AuthenticationBackend::CHALLENGE
    @email = response_hash[:email]
    @secret_code = response_hash[:secret_code]
    if response_hash[:cognito_response].nil?
      retry_response(response_hash)
    else
      cognito_response(response_hash)
    end
  end

  def to_h
    instance_variables.map { |var| [var.to_s.delete('@').to_sym, instance_variable_get(var)] }.to_h
  end

  private

  def cognito_response(response_hash)
    cognito_response = response_hash[:cognito_response]
    @challenge_name = cognito_response[:challenge_name]
    @session_id = cognito_response[:session]
    @challenge_parameters = cognito_response[:challenge_parameters]
  end

  def retry_response(response_hash)
    @flash_message = response_hash[:flash_message]
    @challenge_name = response_hash[:challenge_name]
    @session_id = response_hash[:session_id]
    @challenge_parameters = response_hash[:challenge_parameters]
  end
end
