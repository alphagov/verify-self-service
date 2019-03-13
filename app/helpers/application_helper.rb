module ApplicationHelper
   # @return the path to the login page
  def login_url
    '/auth/cognito-idp/'
  end

  def logout_url
    host = "#{request.protocol}#{request.host}:#{request.port}" || "http://localhost:3000"
    URI::HTTPS.build(
        host: Rails.application.secrets.cognito_user_pool_site,
        path: "/logout",
        query: {
            "client_id": Rails.application.secrets.cognito_client_id,
            "logout_uri": "#{host}/logout/callback"
        }.to_query)
  end
end
