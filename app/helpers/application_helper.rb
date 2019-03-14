module ApplicationHelper
   # @return the path to the login page
  def login_url
    AUTH_LOGIN_PATH
  end

  def logout_url
    if session[:provider] == 'cognito-idp'
        host = "#{request.protocol}#{request.host}:#{request.port}" || "http://localhost:3000"
        URI.join(
            Rails.application.secrets.cognito_user_pool_site,
            "logout?"+
            {
                "client_id": Rails.application.secrets.cognito_client_id,
                "logout_uri": "#{host}#{logout_callback_path}"
            }.to_query).to_s
    else
        logout_callback_path
    end
    
  end
end
