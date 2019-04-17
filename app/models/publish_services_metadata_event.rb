class PublishServicesMetadataEvent < Event
  data_attributes :event_id, :services_metadata
  validates_presence_of :event_id
  before_create :populate_data_attributes
  after_create :upload
  has_one_attached :document
  
  def populate_data_attributes
    assign_attributes(services_metadata: services_metadata)
  end

  def upload
    file_name = 'servicesmetadata.json'

    document.attach(
      io: StringIO.new(services_metadata),
      content_type: 'application/json',
      filename: file_name
    )
  end

  private

  def services_metadata
    Component.to_service_metadata(event_id)
  end
end
