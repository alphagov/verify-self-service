class ApplicationController < ActionController::Base
  include UserInfo
  include ApplicationHelper
  before_action :authenticate_user!
  before_action :set_user
  before_action :configure_permitted_parameters, if: :devise_controller?

protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[given_name family_name roles])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[user_id phone_number given_name family_name roles session_only])
    devise_parameter_sanitizer.permit(:sign_in, keys: %i[totp_code])
  end

  # Sets the current user into a named Thread location so that it can be accessed by models and observers
  def set_user
    UserInfo.current_user = authenticate_user!
  end
end
