require 'auth/authentication_backend'

module Devise
  module Models
    module RemoteAuthenticatable
      extend ActiveSupport::Concern
      include AuthenticationBackend

      def remote_authentication(params)
        resp = authentication_flow(params)

        if resp.response_type == AuthenticationBackend::CHALLENGE
          create_challenge_flow(resp)
        else
          complete_auth(resp)
        end
        self
      end

      def create_challenge_flow(resp)
        self.email = resp.email
        self.challenge_name = resp.challenge_name
        self.cognito_session_id = resp.session_id
        self.challenge_parameters = resp.challenge_parameters
        self.secret_code = resp.secret_code
        self
      end

      def complete_auth(resp)
        claims = get_user_info(resp.id_token)[0]
        self.login_id = claims['email']
        self.user_id = claims['sub']
        self.email = claims['email']
        self.phone_number = claims['phone_number']
        self.access_token = resp.access_token
        self.roles = claims['custom:roles']
        self.permissions = UserRolePermissions.new(claims['custom:roles'], claims['email'])
        self.full_name = "#{claims['given_name']} #{claims['family_name']}"
        self.given_name = claims['given_name']
        self.family_name = claims['family_name']
        self.team = Team.find_by_team_alias(claims['cognito:groups'][0])&.id unless claims['cognito:groups'].nil?
        self.cognito_groups = claims['cognito:groups']
        self.mfa = claims['mfa'] || resp.params[:challenge_name]
        self.session_start_time = Time.now.to_s
        self
      end

      def get_user_info(jwt)
        JWT.decode(jwt, nil, true, algorithms: %w[RS256], jwks: SelfService.service(:jwks))
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
