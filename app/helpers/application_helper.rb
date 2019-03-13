module ApplicationHelper
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
