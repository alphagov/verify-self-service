class TriggerMetadataEventCallback
  def after_save(model)
    PublishServicesMetadataEvent.create(
      event_id: model.id,
      environment: environment(model),
    )
  end

  def self.publish
    TriggerMetadataEventCallback.new
  end

private

  def environment(model)
    if model.aggregate.respond_to?(:component)
      model.aggregate.component.environment
    elsif model.respond_to?(:service)
      if SpComponent.find_by_id(model.sp_component_id).present?
        SpComponent.find_by_id(model.sp_component_id).environment
      else
        MsaComponent.find_by_id(model.msa_component_id).environment
      end
    else
      model.aggregate.environment
    end
  end
end
