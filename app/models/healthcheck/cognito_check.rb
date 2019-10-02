require "auth/authentication_backend"

module Healthcheck
  class CognitoCheck
    include AuthenticationBackend
    def name
      :cognito_connectivity
    end

    def status
      authentication_backend_status
    end
  end
end
