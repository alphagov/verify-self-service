require 'yaml'
require 'digest/md5'
require 'notify/notification'
require 'polling/worker'

class PublishServicesMetadataEvent < Event
  include HubEnvironmentConcern
  include Notification
  attr_reader :metadata

  data_attributes :event_id, :services_metadata, :environment
  validates_presence_of :event_id
  before_create :populate_data_attributes
  before_create :upload
  after_create_commit Worker.poll

  def populate_data_attributes
    @metadata = services_metadata
    assign_attributes(services_metadata: metadata)
  end

  def upload
    SelfService.service(:storage_client).put_object(
      bucket: hub_environment(environment, :bucket),
      key: FILES::CONFIG_METADATA,
      body: StringIO.new(metadata.to_json),
      server_side_encryption: 'AES256',
      acl: 'bucket-owner-full-control',
    )
    out_of_hours_notification if environment == 'production'
  rescue Aws::S3::Errors::ServiceError
    Rails.logger.error("Failed to publish config metadata for event #{event_id}")
    raise ActiveRecord::Rollback
  end

private

  def services_metadata
    Component.to_service_metadata(event_id, environment)
  end

  def out_of_hours_notification
    if out_of_hours?
      event = Event.find_by_id(event_id)
      team = Team.find_by_id(current_user.team)
      send_out_of_hours_rotation_email(event_type: event.type, user: current_user, team: team)
    end
  end

  def out_of_hours?
    Time.zone = 'London'
    Time.zone.now.on_weekend? || !Time.zone.now.hour.between?(8, 17)
  end
end
