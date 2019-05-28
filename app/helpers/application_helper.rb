module ApplicationHelper
  # @return the path to the login page
  def login_url
    AUTH_LOGIN_PATH
  end

  def logout_url
    if session[:provider] == 'cognito-idp'
      query_params = {
              "client_id": Rails.application.secrets.cognito_client_id,
              "logout_uri": logout_callback_url
          }.to_query
      URI.join(
        Rails.application.secrets.cognito_user_pool_site,
        "logout?#{query_params}"
      ).to_s
    else
      logout_callback_url
    end
  end

  def format_date_time(cert_date_time)
    cert_date_time.strftime("%e-%m-%Y %H:%M")
  end
end
