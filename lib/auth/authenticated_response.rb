require_relative 'authentication_backend'

class AuthenticatedResponse
  attr_reader :response_type, :params, :id_token, :access_token

  def initialize(params:, cognito_response:)
    @response_type = AuthenticationBackend::AUTHENTICATED
    @params = params
    @id_token = cognito_response[:authentication_result][:id_token]
    @access_token = cognito_response[:authentication_result][:access_token]
  end
end
