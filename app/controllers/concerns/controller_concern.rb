module ControllerConcern
  extend ActiveSupport::Concern

  def component_key(params)
    params.keys.find { |m| m.include?('component_id') }
  end

  def component_name_from_params(params)
    key = component_key(params)
    key.gsub('_id', '').split('_').map(&:titleize).join
  end

  def publish_event_has_not_occured(event_id)
    PublishServicesMetadataEvent.where("data->>'event_id' = ?", event_id).empty?
  end

  def check_metadata_published_user_journey(event_id)
    publish_event_has_not_occured(event_id) ? false : true
  end

  def check_metadata_published(event_id)
    if publish_event_has_not_occured(event_id)
      flash[:notice] = t('certificates.errors.cannot_publish')
    end
  end
end
