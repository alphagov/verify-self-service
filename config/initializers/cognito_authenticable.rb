require 'aws-sdk-cognitoidentityprovider'
require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    class CognitoAuthenticatable < Authenticatable
      def authenticate!
        clean_up_session
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
            unless params.dig(:user,:cognito_session_id).nil?
                resp = client.respond_to_auth_challenge(
                  {client_id: Rails.application.secrets.cognito_client_id,
                  session: params[:user][:cognito_session_id], challenge_name: "SOFTWARE_TOKEN_MFA",
                  challenge_responses: { "USERNAME": params[:user][:email], "SOFTWARE_TOKEN_MFA_CODE": params[:user][:totp_code] }}
                )
            else
              resp = client.initiate_auth(
                client_id: Rails.application.secrets.cognito_client_id,
                auth_flow: "USER_PASSWORD_AUTH",
                auth_parameters: {
                  "USERNAME" => email,
                  "PASSWORD" => password
                }
              )
            end
            
            if resp
              if resp.challenge_name.present? && !resp.challenge_name.nil?
                session[:challenge_name] = resp.challenge_name
                session[:cognito_session_id] = resp.session
                session[:challenge_parameters] = resp.challenge_parameters
                session[:username] = email
                redirect!(Rails.application.routes.url_helpers.new_user_session_path)
              else
                user = User.where(email: email).try(:first)
                if user
                  success!(user)
                else
                  user = User.create(email: email, password: "", password_confirmation: "")
                  if user.valid?
                    success!(user)
                  else
                    return fail(:failed_to_create_user)
                  end
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

      private 

      def clean_up_session
        unless params.dig(:user,:cognito_session_id).nil?
          session.delete(:challenge_name)
          session.delete(:cognito_session_id)
          session.delete(:challenge_parameters)
          session.delete(:username)
        end
      end
    end
  end
end