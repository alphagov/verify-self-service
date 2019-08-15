class TriggerMetadataEventCallback
  def after_save(model)
    PublishServicesMetadataEvent.create(
      event_id: model.id,
      environment: environment(model)
    )
  end

  def self.publish
    TriggerMetadataEventCallback.new
  end

private

  def environment(model)
    if model.aggregate.respond_to?(:component)
      model.aggregate.component.environment
    else
      model.aggregate.environment
    end
  end
end
