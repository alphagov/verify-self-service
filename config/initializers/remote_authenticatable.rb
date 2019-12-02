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
              if resource.challenge_name
                populate_session_for_auth_challenge(resource)
                redirect!(Rails.application.routes.url_helpers.new_user_session_path)
              else
                clean_up_session
                UserSignInEvent.create(user_id: resource.user_id)
                success!(resource)
              end
            else
              clean_up_session
              return fail!(:unknown_cognito_response)
            end
          rescue AuthenticationBackend::NotAuthorizedException => error
            clean_up_session
            Rails.logger.warn error
            return fail!(:invalid_login)
          rescue AuthenticationBackend::TemporaryPasswordExpiredException => error
            clean_up_session
            Rails.logger.warn error
            return fail!(:temporary_password_expired)
          rescue AuthenticationBackend::PasswordResetRequiredException => error
            Rails.logger.error error
            clean_up_session
            return redirect!(Rails.application.routes.url_helpers.force_user_reset_password_path(email: params[:user][:email], reset_by_admin: true))
          rescue StandardError => error
            Rails.logger.error error
            clean_up_session
            return fail!(:unknown_cognito_response)
          end
        end
      end

      private

      def populate_session_for_auth_challenge(resource)
        session[:email] = resource.email
        session[:challenge_name] = resource.challenge_name
        session[:cognito_session_id] = resource.cognito_session_id
        session[:challenge_parameters] = resource.challenge_parameters
        session[:secret_code] = resource.secret_code
      end

      def populate_session_for_mfa_enrolment(resource)
        session[:access_token] = resource.access_token
        session[:email] = resource.email
      end

      def populate_auth_params(auth_params)
        auth_params[:email] = session[:email]
        auth_params[:cognito_session_id] = session[:cognito_session_id]
        auth_params[:challenge_name] = session[:challenge_name]
        auth_params[:challenge_parameters] = session[:challenge_parameters]
        auth_params[:secret_code] = session[:secret_code]
        clean_up_session
      end

      def clean_up_session
        return false unless params.dig(:user, :cognito_session_id)

        session.delete(:challenge_name)
        session.delete(:cognito_session_id)
        session.delete(:challenge_parameters)
        session.delete(:email)
        session.delete(:access_token)
        session.delete(:secret_code)
      end
    end
  end
end
