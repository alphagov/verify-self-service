class ApplicationController < ActionController::Base
  include Pundit
  include UserInfo
  include ApplicationHelper

  protect_from_forgery
  before_action :authenticate_user!
  before_action :set_user
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :check_authorization

protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: %i[totp_code new_password])
  end

  # Sets the current user into a named Thread location so that it can be accessed by models and observers
  def set_user
    UserInfo.current_user = authenticate_user!
  end

  def check_authorization
    authorize "#{request.params[:controller].titlecase.gsub(/\s+/, '')}Controller".constantize.new
  rescue Pundit::NotAuthorizedError
    flash[:warn] = t('shared.errors.authorisation')
    redirect_to root_path
  end
end
