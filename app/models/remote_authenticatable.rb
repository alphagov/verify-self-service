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

        if params.has_key?(:cognito_session_id)
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

        if resp.challenge_name.present?
          self.challenge_name = resp[:challenge_name]
          self.cognito_session_id = resp[:session]
          self.challenge_parameters = resp[:challenge_parameters]
          self.email = params[:email]
        else
          # Get User Information
          aws_user = client.get_user(access_token: resp[:authentication_result][:access_token])
          user_attributes = aws_user.user_attributes.map { |attribute| [attribute.name, attribute.value] }.to_h
          self.login_id = params[:email]
          self.user_id = aws_user.username
          self.email = user_attributes["email"]
          self.access_token = resp[:authentication_result][:access_token]
          self.organisation = user_attributes["custom:organisation"]
          self.roles = user_attributes["custom:roles"]
          self.full_name = "#{user_attributes['given_name']} #{user_attributes['family_name']}"
          self.given_name = user_attributes["given_name"]
          self.family_name = user_attributes["family_name"]
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
          resource.login_id = data['login_id']
          resource.user_id = data['user_id']
          resource.email = data['email']
          resource.access_token = data['access_token']
          resource.organisation = data['organisation']
          resource.roles = data['roles']
          resource.full_name = "#{data['given_name']} #{data['family_name']}"
          resource.given_name = data['given_name']
          resource.family_name = data['family_name']
          resource
        end

        #
        # Here you have to return an array with the data of your resource
        # that you want to serialize into the session
        #
        # You might want to include some authentication data
        #
        def serialize_into_session(record)
          [
              {
                  email: record.email,
                  access_token: record.access_token,
                  login_id: record.login_id,
                  user_id: record.user_id,
                  organisation: record.organisation,
                  roles: record.roles,
                  given_name: record.given_name,
                  family_name: record.family_name,
              },
              # Used for salt in serialize_from_session, causes error if missing
              nil
          ]
        end
      end
    end
  end
end
