module ControllerConcern
  extend ActiveSupport::Concern

  def component_key(params)
    params.keys.find { |m| m.include?('component_id') }
  end

  def component_name_from_params(params)
    key = component_key(params)
    key.gsub('_id', '').split('_').map(&:titleize).join
  end

  def check_metadata_published(event_id)
    if PublishServicesMetadataEvent.where("data->>'event_id' = ?", event_id).empty?
      flash[:notice] = t('certificates.errors.cannot_publish')
    end
  end
end
