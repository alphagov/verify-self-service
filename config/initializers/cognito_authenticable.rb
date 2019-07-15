require 'aws-sdk-cognitoidentityprovider'
require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    class CognitoAuthenticatable < Authenticatable
      def authenticate!
        if params[:user]
          if Rails.application.secrets.cognito_aws_access_key_id.present? &&
              Rails.application.secrets.cognito_aws_secret_access_key.present?
            client = Aws::CognitoIdentityProvider::Client.new(
              region: Rails.application.secrets.aws_region,
              access_key_id: Rails.application.secrets.cognito_aws_access_key_id,
              secret_access_key: Rails.application.secrets.cognito_aws_secret_access_key
            )
          else
            client = Aws::CognitoIdentityProvider::Client.new
          end

          begin
            resp = client.initiate_auth(
              client_id: Rails.application.secrets.cognito_client_id,
              auth_flow: "USER_PASSWORD_AUTH",
              auth_parameters: {
                "USERNAME" => email,
                "PASSWORD" => password
              }
            )

            if resp
              user = User.where(email: email).try(:first)
              if user
                success!(user)
              else
                user = User.create(email: email, password: password, password_confirmation: password)
                if user.valid?
                  success!(user)
                else
                  return fail(:failed_to_create_user)
                end
              end
            else
              return fail(:unknown_cognito_response)
            end
          rescue Aws::CognitoIdentityProvider::Errors::NotAuthorizedException
            return fail(:invalid_login)
          rescue Aws::CognitoIdentityProvider::Errors::UserNotFoundException
            return fail(:invalid_login)
          rescue StandardError
            return fail(:unknown_cognito_response)
          end

        end
      end

      def email
        params[:user][:email]
      end

      def password
        params[:user][:password]
      end
    end
  end
end
