class PublishServicesMetadataEvent < Event
  
  data_attributes :event_id, :cert_config
  before_create :populate_data_attributes
  after_create :upload
  has_one_attached :document

  def populate_data_attributes
    assign_attributes(attributes_to_apply)
  end

  def attributes_to_apply
    event_id = self.event_id
    services_metadata = ServicesMetadata.to_json(self.event_id)

    { event_id: event_id, cert_config: services_metadata }
  end

  def upload
    file_name = "#{ServicesMetadata.name.downcase}.json"
    json_data = attributes_to_apply[:cert_config]
    document.attach(
      io: StringIO.new(json_data),
      content_type: 'application/json',
      filename: file_name
    )
  end

end
