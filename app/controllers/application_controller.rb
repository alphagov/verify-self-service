class ApplicationController < ActionController::Base
  include UserInfo
  include ApplicationHelper
  before_action :authenticate_user!
  before_action :set_user
  before_action :configure_permitted_parameters, if: :devise_controller?

  before_action :set_locale

protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: %i[totp_code])
  end

  # Sets the current user into a named Thread location so that it can be accessed by models and observers
  def set_user
    UserInfo.current_user = authenticate_user!
  end

private

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end
end
