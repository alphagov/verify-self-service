class TriggerMetadataEventCallback
  def after_save(model)
    PublishServicesMetadataEvent.create(event_id: model.id)
  end
  
  def self.publish
    TriggerMetadataEventCallback.new
  end
end