require 'yaml'
require 'digest/md5'

class PublishServicesMetadataEvent < Event
  attr_reader :metadata
  data_attributes :event_id, :services_metadata, :environment
  validates_presence_of :event_id
  before_create :populate_data_attributes
  before_create :upload

  def populate_data_attributes
    @metadata = services_metadata
    assign_attributes(services_metadata: metadata)
  end

  def upload
    SelfService.service(:storage_client).put_object(
      bucket: hub_environment_bucket,
      key: FILES::CONFIG_METADATA,
      body: StringIO.new(metadata.to_json),
      server_side_encryption: 'AES256',
      acl: 'bucket-owner-full-control',
    )
  rescue Aws::S3::Errors::ServiceError
    Rails.logger.error("Failed to publish config metadata for event #{event_id}")
    raise ActiveRecord::Rollback
  end

private

  def services_metadata
    Component.to_service_metadata(event_id, environment)
  end

  def hub_environment_bucket
    Rails.configuration.hub_environments_legacy.fetch(environment)
  rescue KeyError
    Rails.logger.error("Failed to find bucket for #{environment}")
    "#{environment}-bucket"
  end
end
