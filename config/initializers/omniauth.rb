OmniAuth.config.logger = Rails.logger

if  Rails.application.secrets.cognito_client_id.present?
    Rails.application.config.middleware.use OmniAuth::Strategies::CognitoIdP,
        Rails.application.secrets.cognito_client_id,
        Rails.application.secrets.cognito_client_secret,
        scope: 'email openid aws.cognito.signin.user.admin profile',
        aws_region: Rails.application.secrets.cognito_aws_region,
        user_pool_id: Rails.application.secrets.cognito_user_pool_id,
        client_options: {
            site: Rails.application.secrets.cognito_user_pool_site
        }
    login_path='/auth/cognito-idp'
end

if %w(test development).include? Rails.env    
    Rails.application.config.middleware.use OmniAuth::Builder do
        provider :developer, :fields => [:name, :email, :phone, :first_name, :last_name], :uid_field => :last_name
    end
    login_path='/devauth'
end

login_path='/auth/developer' if Rails.env.test?

OmniAuth.config.on_failure = Proc.new { |env|
  message_key = env['omniauth.error.type']
  error_description = Rack::Utils.escape(env['omniauth.error'].error_reason)
  new_path = "#{OmniAuth.config.path_prefix}/failure?error_type=#{message_key}&error_msg=#{error_description}"
  Rack::Response.new(['302 Moved'], 302, 'Location' => new_path).finish
}

AUTH_LOGIN_PATH=login_path

