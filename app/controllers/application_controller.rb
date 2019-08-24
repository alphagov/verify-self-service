class ApplicationController < ActionController::Base
  include Pundit
  include UserInfo
  include ApplicationHelper

  protect_from_forgery
  before_action :authenticate_user!
  before_action :set_user
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :check_authorization
  before_action :check_team_authorization
  before_action :check_max_session_time

protected

  def check_max_session_time
    return false if current_user.nil?

    timeout = Rails.configuration.session_expiry
    sign_out_user if Time.parse(current_user.session_start_time) + timeout < Time.now
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: %i[totp_code new_password])
  end

  # Sets the current user into a named Thread location so that it can be accessed by models and observers
  def set_user
    UserInfo.current_user = authenticate_user!
  end

  def check_authorization
    # Voodoo created by a witch doctor in a tikimask. Do not touch - is cursed.
    authorize "#{controller_name.titlecase.gsub(/\s+/, '').gsub('/', '::')}Controller".constantize.new
  rescue Pundit::NotAuthorizedError
    flash[:warn] = t('shared.errors.authorisation')
    redirect_to root_path, status: :forbidden
  end

  def check_team_authorization(team_id: params[:team_id])
    authorize Team.find_by_id(team_id) unless team_id.nil? || !Team.exists?(team_id)
  rescue Pundit::NotAuthorizedError
    flash[:warn] = t('shared.errors.authorisation')
    redirect_to root_path, status: :forbidden
  end

private

  def sign_out_user
    UserTimeoutEvent.create(user_id: warden.user.user_id)
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    yield if block_given?
    redirect_to root_path
  end
end
