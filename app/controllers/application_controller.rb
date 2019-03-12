class ApplicationController < ActionController::Base
  # Is the user signed in?
  # @return [Boolean]
  def user_signed_in?
    session[:userinfo].present?
  end

  # Set the @current_user or redirect to public page
  def authenticate_user!
    # Redirect to page that has the login here
    if user_signed_in?
      @current_user = session[:userinfo]
    else
      session[:redirect_path] = request&.fullpath
      redirect_to login_url
    end
  end

  # What's the current_user?
  # @return [Hash]
  def current_user
    @current_user
  end

  # @return the path to the login page
  def login_url
    '/auth/cognito-idp/'
  end

  def logout_url
    host = "#{request.protocol}#{request.host}:#{request.port}" || "http://localhost:3000"
    Rails.application.secrets.cognito_user_pool_site + 
    "logout?client_id=" + Rails.application.secrets.cognito_client_id +
    "&logout_uri=#{host}/logout/callback"
  end
end
