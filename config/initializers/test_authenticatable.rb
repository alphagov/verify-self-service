require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    class TestAuthenticatable < Authenticatable
      def authenticate!
        unless Rails.env == "test"
          fail(:invalid_login)
        end
        if params[:user]
          auth_params = params[:user]
          
          if auth_params[:email] == 'invalid@email.com'
            fail(:invalid_login)
          elsif auth_params[:email] == 'unregistered@example.com'
            fail(:invalid_login)
          elsif auth_params[:password] == 'invalidpassword'
            fail(:invalid_login)
          else
            resource = mapping.to.new
            resource.given_name = "Test"
            resource.family_name = "User"
            resource.full_name = "Test User"
            resource.email = auth_params[:email]
            resource.roles = "dev"
            resource.organisation = "Test Org"
            return fail! unless resource
            begin
              if validate(resource)
                  success!(resource)
                end
            rescue StandardError => e
              puts "Error #{e.message}"
              return fail(:unknown_cognito_response)
            end
          end
        end
      end
    end
  end
end
