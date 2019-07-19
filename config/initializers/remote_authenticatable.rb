require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    class RemoteAuthenticatable < Authenticatable
      def authenticate!
        clean_up_session
        if params[:user]
          # auth_params = authentication_hash
          # auth_params[:password] = password
          auth_params = params[:user]
          resource = mapping.to.new

          return fail! unless resource
          #binding.pry
          begin
            if validate(resource)
              resource = resource.remote_authentication(auth_params)
              if resource.access_token.nil?
                session[:challenge_name] = resource.challenge_name
                session[:cognito_session_id] = resource.cognito_session_id
                session[:challenge_parameters] = resource.challenge_parameters
                session[:username] = resource.email
                redirect!(Rails.application.routes.url_helpers.new_user_session_path,
                  {
                    challenge_name: resource.challenge_name,
                    cognito_session: resource.cognito_session_id,
                    challenge_parameters: resource.challenge_parameters,
                    username:resource.email,
                  })
              else
                binding.pry
                success!(resource)
              end
            else
              puts "Returning unknown cognito response 1"
              return fail(:unknown_cognito_response)
            end
        
          rescue Aws::CognitoIdentityProvider::Errors::NotAuthorizedException
            return fail(:invalid_login)
          rescue Aws::CognitoIdentityProvider::Errors::UserNotFoundException
            return fail(:invalid_login)
          rescue StandardError => e
            puts "Error #{e.message}"
            return fail(:unknown_cognito_response)
          end
        end
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
