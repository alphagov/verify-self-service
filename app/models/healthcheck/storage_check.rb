module Healthcheck
  class StorageCheck
    include Utilities::Configuration::Settings

    def name
      :storage_connectivity
    end

    def status
      healthcheck_key = 'healthcheck.txt'

      unless service.exist?(healthcheck_key)
        service.upload(healthcheck_key, '')
      end

      OK
    end

    def service
      @service ||= ActiveStorage::Service.configure(
        Rails.configuration.active_storage.service,
        configuration('storage.yml')
      )
    end
  end
end
