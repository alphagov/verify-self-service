module Devise
  module Models
    module RemoteAuthenticatable
      extend ActiveSupport::Concern

      #
      # Here you do the request to the external webservice
      #
      # If the authentication is successful you should return
      # a resource instance
      #
      # If the authentication fails you should return false
      #
      #def remote_authentication(authentication_hash)
      def remote_authentication(params)
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

        if params.dig(:cognito_session_id).present?
          resp = client.respond_to_auth_challenge(
            client_id: Rails.application.secrets.cognito_client_id,
             session: params[:cognito_session_id], challenge_name: "SOFTWARE_TOKEN_MFA",
             challenge_responses: { "USERNAME": params[:email], "SOFTWARE_TOKEN_MFA_CODE": params[:totp_code] }
          )
        else
          resp = client.initiate_auth(
            client_id: Rails.application.secrets.cognito_client_id,
            auth_flow: "USER_PASSWORD_AUTH",
            auth_parameters: {
                "USERNAME" => params[:email],
                "PASSWORD" => params[:password]
              }
          )
        end

        if resp.challenge_name.present? && !resp.challenge_name.nil?
          self.challenge_name = resp[:challenge_name]
          self.cognito_session_id = resp[:session]
          self.challenge_parameters = resp[:challenge_parameters]
          self.email = params[:email]
        else
          self.email = params[:email]
          self.access_token = resp[:authentication_result][:access_token]
        end
        self
      end

      module ClassMethods
        ####################################
        # Overriden methods from Devise::Models::Authenticatable
        ####################################

        #
        # This method is called from:
        # Warden::SessionSerializer in devise
        #
        # It takes as many params as elements had the array
        # returned in serialize_into_session
        #
        # Recreates a resource from session data
        #
        def serialize_from_session(data, _salt)
          resource = self.new
          resource.email = data['email']
          resource.access_token = data['access_token']
          resource
        end

        #
        # Here you have to return and array with the data of your resource
        # that you want to serialize into the session
        #
        # You might want to include some authentication data
        #
        def serialize_into_session(record)
          [
              {
                  email: record.email,
                  access_token: record.access_token
              },
              nil
          ]
        end
      end
    end
  end
end
