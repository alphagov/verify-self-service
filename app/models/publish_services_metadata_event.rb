require 'yaml'
require 'digest/md5'
require 'utilities/configuration/settings'

class PublishServicesMetadataEvent < Event
  include Utilities::Configuration::Settings

  attr_reader :storage_key, :json_data
  data_attributes :event_id, :services_metadata
  validates_presence_of :event_id
  before_create :populate_data_attributes
  after_create :upload
  
  def populate_data_attributes
    @json_data = services_metadata
    assign_attributes(services_metadata: json_data)
  end

  def upload
    @storage_key = "verify_services_metadata.json"
    check_sum = Digest::MD5.base64digest(json_data)
    current_active_storage_env = Rails.configuration.active_storage.service
    service = ActiveStorage::Service.configure(
      current_active_storage_env, configuration('storage.yml')
    )
    service.upload(storage_key, StringIO.new(json_data), checksum: check_sum)
  end

  private

  def services_metadata
    Component.to_service_metadata(event_id)
  end
end
