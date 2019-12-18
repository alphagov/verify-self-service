require 'api/hub_config_api'

module Healthcheck
  class HubCheck
    def name
      :hub_connectivity
    end

    def status
      Rails.configuration.hub_environments.keys.each do |environment|
        response = HUB_CONFIG_API.healthcheck(environment)

        return UNAVAILABLE unless response.status == 200
      end
      OK
    end
  end
end
