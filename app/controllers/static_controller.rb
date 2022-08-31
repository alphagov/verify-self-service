class StaticController < ActionController::Base
  include Pundit::Authorization

  layout 'full_width_layout'
end
