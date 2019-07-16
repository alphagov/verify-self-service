class ApplicationController < ActionController::Base
  include ApplicationHelper
  before_action :authenticate_user!
end
