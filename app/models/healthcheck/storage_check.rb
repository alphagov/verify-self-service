module Healthcheck
  class StorageCheck
    def name
      :storage_connectivity
    end

    def status
      healthcheck_key = 'healthcheck.txt'

      unless SelfService.service(:storage_client).exist?(healthcheck_key)
        SelfService.service(:storage_client).upload(healthcheck_key, '')
      end

      OK
    end
  end
end
