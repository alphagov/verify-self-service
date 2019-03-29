
class PublishServicesMetadataEvent < Event
  
  data_attributes :event_id, :cert_config
  before_create :populate_data_attributes

  def populate_data_attributes
    self.assign_attributes(attributes_to_apply)
  end

  def attributes_to_apply
    { event_id: self.event_id, cert_config: ServicesMetadata.to_json }
  end

end
