module ControllerConcern
  extend ActiveSupport::Concern

  def component_key(params)
    params.keys.find { |m| m.include?('component_id') }
  end

  def component_name_from_params(params)
    key = component_key(params)
    key.gsub('_id', '').split('_').map(&:titleize).join
  end
end
