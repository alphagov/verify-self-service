class TriggerMetadataEventCallback
  def after_save(model)
    env = environment(model)
    return if env.nil?

    PublishServicesMetadataEvent.create(
      event_id: model.id,
      environment: env,
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
      if model.service.sp_component_id.present?
        model.service.sp_component.environment
      elsif model.service.msa_component_id.present?
        model.service.msa_component.environment
      end
    else
      model.aggregate.environment
    end
  end
end
