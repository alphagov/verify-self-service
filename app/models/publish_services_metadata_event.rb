
class PublishServicesMetadataEvent < Event
  data_attributes :cert_config
  before_create :populate_data_attributes

  def populate_data_attributes
    self.assign_attributes(attributes_to_apply)
  end

  def attributes_to_apply
    {cert_config: "I am here" }
  end
end
