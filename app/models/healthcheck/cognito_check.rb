module Healthcheck
  class CognitoCheck
    def name
      :cognito_connectivity
    end

    def status
      SelfService.service(:cognito_client).describe_user_pool(
        user_pool_id: Rails.application.secrets.cognito_user_pool_id
      )
      OK
    end
  end
end
