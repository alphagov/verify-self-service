require 'net/http'

module Healthcheck
  class HubCheck
    def name
      :hub_connectivity
    end

    def status
      url = URI.join(Rails.configuration.hub_config_host, 'service-status')
      req = Net::HTTP::Get.new(url.to_s)
      res = Net::HTTP.start(url.host, url.port,
                            use_ssl: url.scheme == 'https',
                            open_timeout: 3,
                            read_timeout: 3) { |http|
        http.request(req)
      }

      return OK if res.code == "200"
    end
  end
end
