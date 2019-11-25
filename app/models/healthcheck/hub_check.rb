require 'api/hub_config_api'

module Healthcheck
  class HubCheck
    def name
      :hub_connectivity
    end

    def status
      response = HUB_CONFIG_API.healthcheck

      return OK if response.status == 200
    end
  end
end
