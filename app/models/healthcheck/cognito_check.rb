require 'auth/authentication_backend'

module Healthcheck
  include AuthenticationBackend

  class CognitoCheck
    def name
      :cognito_connectivity
    end

    def status
      authentication_backend_status
    end
  end
end
