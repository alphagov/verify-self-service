require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    class RemoteAuthenticatable < Authenticatable
      def authenticate!
        if params[:user]
          auth_params = params[:user]
          resource = mapping.to.new
          populate_auth_params(auth_params) if session.key?('cognito_session_id')
          return fail! unless resource

          begin
            if validate(resource)
              resource = resource.remote_authentication(auth_params)
              if resource.access_token.nil?
                populate_session_for_2fa(resource)
                redirect!(Rails.application.routes.url_helpers.new_user_session_path)
              else
                success!(resource)
              end
            else
              clean_up_session
              return fail!(:unknown_cognito_response)
            end
          rescue Aws::CognitoIdentityProvider::Errors::NotAuthorizedException,
                 Aws::CognitoIdentityProvider::Errors::UserNotFoundException,
                 Aws::CognitoIdentityProvider::Errors::InvalidParameterException,
                 Aws::CognitoIdentityProvider::Errors::CodeMismatchException
            clean_up_session
            return fail!(:invalid_login)
          rescue StandardError
            clean_up_session
            return fail!(:unknown_cognito_response)
          end
        end
      end

      private

      def populate_session_for_2fa(resource)
        session[:challenge_name] = resource.challenge_name
        session[:cognito_session_id] = resource.cognito_session_id
        session[:challenge_parameters] = resource.challenge_parameters
        session[:username] = resource.email
      end

      def populate_auth_params(auth_params)
        auth_params[:email] = session[:username]
        auth_params[:cognito_session_id] = session[:cognito_session_id]
        auth_params[:challenge_name] = session[:challenge_name]
        auth_params[:challenge_parameters] = session[:challenge_parameters]
        clean_up_session
      end

      def clean_up_session
        return false unless params.dig(:user, :cognito_session_id)

        session.delete(:challenge_name)
        session.delete(:cognito_session_id)
        session.delete(:challenge_parameters)
        session.delete(:username)
      end
    end
  end
end
