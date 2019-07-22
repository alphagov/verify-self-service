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
      def remote_authentication(params)
        if params.key?(:cognito_session_id)
          resp = send_2fa(params[:email], params[:cognito_session_id], params[:totp_code])
        else
          resp = initiate_auth(params[:email], params[:password])
        end
        return process_response(resp, params) if resp.present?

        raise StandardError("No Response Back from AWS to process")
      end

      def process_response(resp, params)
        if resp.challenge_name.present?
          create_2fa_flow(resp, params)
        else
            # Get User Information
          auth_complete(resp, params)
        end
        self
      end

      def initiate_auth(email, password)
        client = SelfService.service(:cognito_client)
        client.initiate_auth(
          client_id: cognito_client_id,
          auth_flow: 'USER_PASSWORD_AUTH',
          auth_parameters: {
            'USERNAME' => email,
            'PASSWORD' => password
          }
          )
      end

      def send_2fa(email, session_id, totp_code)
        client = SelfService.service(:cognito_client)
        client.respond_to_auth_challenge(
          client_id: cognito_client_id,
          session: session_id,
          challenge_name: 'SOFTWARE_TOKEN_MFA',
          challenge_responses: {
            "USERNAME": email,
            "SOFTWARE_TOKEN_MFA_CODE": totp_code
          }
          )
      end

      def create_2fa_flow(resp, params)
        self.challenge_name = resp[:challenge_name]
        self.cognito_session_id = resp[:session]
        self.challenge_parameters = resp[:challenge_parameters]
        self.email = params[:email]
        self
      end

      def auth_complete(resp, params)
        access_token = resp[:authentication_result][:access_token]
        aws_user = get_user_info(access_token)
        user_attributes = get_user_attributes(aws_user)
        self.login_id = params[:email]
        self.user_id = aws_user.username
        self.email = user_attributes['email']
        self.access_token = access_token
        self.organisation = user_attributes['custom:organisation']
        self.roles = user_attributes['custom:roles']
        self.full_name = "#{user_attributes['given_name']} #{user_attributes['family_name']}"
        self.given_name = user_attributes['given_name']
        self.family_name = user_attributes['family_name']
        self
      end

      def get_user_info(access_token)
        client = SelfService.service(:cognito_client)
        client.get_user(access_token: access_token)
      end

      def get_user_attributes(aws_user)
        aws_user.user_attributes.map { |attribute|
          [attribute.name, attribute.value]
        }.to_h
      end

      def cognito_client_id
        Rails.application.secrets.cognito_client_id
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
          resource = new
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
              family_name: record.family_name
            },
            # Used for salt in serialize_from_session, causes error if missing
            nil
          ]
        end
      end
    end
  end
end
