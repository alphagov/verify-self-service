module Healthcheck
  class StorageCheck
    def name
      :storage_connectivity
    end

    def status
      Rails.configuration.hub_environments.values.each do |bucket|
        unless healthcheck_file_exists?(bucket)
          SelfService.service(:storage_client).put_object(
            bucket: bucket,
            key: FILES::HEALTHCHECK,
            body: '',
            server_side_encryption: 'AES256'
          )
        end
      end

      OK
    end

  private

    def healthcheck_file_exists?(bucket)
      SelfService.service(:storage_client).get_object(
        bucket: bucket,
        key: FILES::HEALTHCHECK
      )
    rescue Aws::S3::Errors::NoSuchKey
      false
    end
  end
end
