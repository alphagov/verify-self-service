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
          resp = respond_to_challenge(params)
        else
          resp = initiate_auth(params[:email], params[:password])
        end
        return process_response(resp, params) if resp.present?

        raise StandardError("No Response Back from AWS to process")
      end

      def process_response(resp, params)
        if resp.challenge_name.present?
          create_challenge_flow(resp)
        else
          # Get User Information
          auth_complete(resp, params)
        end
        self
      end

      def initiate_auth(email, password)
        SelfService.service(:cognito_client).initiate_auth(
          client_id: cognito_client_id,
          auth_flow: 'USER_PASSWORD_AUTH',
          auth_parameters: {
            'USERNAME' => email,
            'PASSWORD' => password
          }
        )
      end

      def respond_to_challenge(params)
        challenge_name = params[:challenge_name]
        case challenge_name
        when 'NEW_PASSWORD_REQUIRED'
          challenge_responses = {
            "USERNAME": params[:challenge_parameters]['USER_ID_FOR_SRP'],
            "NEW_PASSWORD": params[:new_password]
          }
        when 'SOFTWARE_TOKEN_MFA'
          challenge_responses = {
            "USERNAME": params[:challenge_parameters]['USER_ID_FOR_SRP'],
            "SOFTWARE_TOKEN_MFA_CODE": params[:totp_code]
          }
        end
        SelfService.service(:cognito_client).respond_to_auth_challenge(
          client_id: cognito_client_id,
          session: params[:cognito_session_id],
          challenge_name: challenge_name,
          challenge_responses: challenge_responses
        )
      end

      def create_challenge_flow(resp)
        self.challenge_name = resp[:challenge_name]
        self.cognito_session_id = resp[:session]
        self.challenge_parameters = resp[:challenge_parameters]
        self
      end

      def auth_complete(resp, params)
        claims = get_user_info(resp[:authentication_result][:id_token])[0]
        self.login_id = claims['email']
        self.user_id = claims['sub']
        self.email = claims['email']
        self.phone_number = claims['phone_number']
        self.access_token = resp[:authentication_result][:access_token]
        self.roles = claims['custom:roles']
        self.permissions = UserRolePermissions.new(claims['custom:roles'], claims['email'])
        self.full_name = "#{claims['given_name']} #{claims['family_name']}"
        self.given_name = claims['given_name']
        self.family_name = claims['family_name']
        self.team = Team.find_by_team_alias(claims['cognito:groups'][0])&.id
        self.cognito_groups = claims['cognito:groups']
        self.mfa = claims['mfa'] || params[:challenge_name]
        self.session_start_time = Time.now.to_s
        self
      end

      def get_user_info(jwt)
        JWT.decode(jwt, nil, true, algorithms: %w[RS256], jwks: SelfService.service(:jwks))
      end

      def cognito_client_id
        Rails.configuration.cognito_client_id
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
          resource.phone_number = data['phone_number']
          resource.access_token = data['access_token']
          resource.roles = data['roles']
          resource.permissions = UserRolePermissions.new(data['roles'], data['email'])
          resource.full_name = "#{data['given_name']} #{data['family_name']}"
          resource.given_name = data['given_name']
          resource.family_name = data['family_name']
          resource.session_start_time = data['session_start_time']
          resource.team = data['team']
          resource.cognito_groups = data['cognito_groups']&.split(',')
          resource
        end

        #
        # Here you have to return an array with the data of your resource
        # that you want to serialize into the session
        #
        # You might want to include some authentication data
        #
        def serialize_into_session(record)
          groups = record.cognito_groups.join(',') unless record.cognito_groups.nil?
          [
            {
              email: record.email,
              phone_number: record.phone_number,
              access_token: record.access_token,
              login_id: record.login_id,
              user_id: record.user_id,
              roles: record.roles,
              given_name: record.given_name,
              family_name: record.family_name,
              session_start_time: record.session_start_time,
              team: record.team,
              cognito_groups: groups
            },
            # Used for salt in serialize_from_session, causes error if missing
            nil
          ]
        end
      end
    end
  end
end
