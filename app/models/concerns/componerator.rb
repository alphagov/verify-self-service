module Componerator
  extend ActiveSupport::Concern

  def klass_component(name)
    name.safe_constantize
  end

  def view_component_type(vsp)
    vsp ? CONSTANTS::VSP_SHORT : CONSTANTS::SP_SHORT
  end
end
