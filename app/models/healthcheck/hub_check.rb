require 'api/hub_config_api'

module Healthcheck
  class HubCheck
    def name
      :hub_connectivity
    end

    def status
      Rails.configuration.hub_environments.keys.each do |environment|
        response = HUB_CONFIG_API.healthcheck(environment)

        unless response.success?
          Rails.logger.error("Error connecting to #{environment} (#{response.env.url}) - status: #{response.status}, body: #{response.body}")
          return UNAVAILABLE
        end
      end
      OK
    end
  end
end
