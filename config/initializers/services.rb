module SelfService

  def self.register_service(name:, client:)
    @services ||= {}

    @services[name] = client
  end

  def self.service(name)
    @services[name] || raise(ServiceNotRegisteredException.new(name))
  end

  class ServiceNotRegisteredException < RuntimeError; end
end

def aws_access_key
  Rails.application.secrets.cognito_aws_access_key_id
end

def aws_secret_key
  Rails.application.secrets.cognito_aws_secret_access_key
end

def cognito_client
  return Aws::CognitoIdentityProvider::Client.new unless aws_access_key.present? && aws_secret_key.present?

  Aws::CognitoIdentityProvider::Client.new(
    region: Rails.application.secrets.aws_region,
    access_key_id: aws_access_key,
    secret_access_key: aws_secret_key
  )
end

SelfService.register_service(
  name: :cognito_client,
  client: cognito_client
)
