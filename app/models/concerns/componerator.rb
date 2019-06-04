module Componerator
  extend ActiveSupport::Concern

  def klass_name(type)
    type.include?('Component') ? type : "#{type.gsub('V', '').titleize}Component"
  end

  def klass_component(name)
    name.safe_constantize
  end
end
