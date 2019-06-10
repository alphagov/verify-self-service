module ComponentConcern
  extend ActiveSupport::Concern

  def klass_component(name)
    name.safe_constantize
  end
end
