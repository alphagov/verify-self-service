module CognitoSupport
  def stub_cognito_response(method:, payload: {})
    SelfService.service(:cognito_client).stub_responses(method, payload)
  end
end
