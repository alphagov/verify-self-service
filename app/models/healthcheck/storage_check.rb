module Healthcheck
  class StorageCheck
    def name
      :storage_connectivity
    end

    def status
      Rails.configuration.hub_environments.values.each do |hub_environment|
        begin
          unless healthcheck_file_exists?(hub_environment['bucket'])
            SelfService.service(:storage_client).put_object(
              bucket: hub_environment[:bucket],
              key: FILES::HEALTHCHECK,
              body: '',
              server_side_encryption: 'AES256',
              acl: 'bucket-owner-full-control',
            )
          end
        rescue Aws::S3::Errors::ServiceError
          raise StandardError.new("Error connecting to #{hub_environment['bucket']} bucket")
        end
      end

      OK
    end

  private

    def healthcheck_file_exists?(bucket)
      SelfService.service(:storage_client).get_object(
        bucket: bucket,
        key: FILES::HEALTHCHECK,
      )
    rescue Aws::S3::Errors::NoSuchKey
      false
    end
  end
end
