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

def stub_client
  Rails.application.secrets.cognito_client_id = SecureRandom.uuid
  client = Aws::CognitoIdentityProvider::Client.new(stub_responses: true)
  client.stub_responses(:initiate_auth, { challenge_name: nil, authentication_result: { access_token: "valid-token" }})
  client.stub_responses(:respond_to_auth_challenge, { challenge_name: nil, authentication_result: {access_token: "valid-token" }})
  client.stub_responses(:get_user, { username: '00000000-0000-0000-0000-000000000000', user_attributes:
    [
      { name: 'sub', value: '00000000-0000-0000-0000-000000000000' },
      { name: 'custom:roles', value: 'gds' },
      { name: 'email_verified', value: 'true' },
      { name: 'phone_number_verified', value: 'true' },
      { name: 'phone_number', value: '+447000000000' },
      { name: 'given_name', value: 'Test' },
      { name: 'family_name', value: 'User' },
      { name: 'email', value: 'test@test.test' }
    ],
  preferred_mfa_setting: 'SOFTWARE_TOKEN_MFA',
  user_mfa_setting_list: ['SOFTWARE_TOKEN_MFA'] })
  client
end

def cognito_client
  return Aws::CognitoIdentityProvider::Client.new if Rails.env == "production"

  if aws_access_key.present? && aws_secret_key.present? && Rails.env != "test"
    Aws::CognitoIdentityProvider::Client.new(
      region: Rails.application.secrets.aws_region,
      access_key_id: aws_access_key,
      secret_access_key: aws_secret_key
    )
  elsif %w(test development).include? Rails.env
    stub_client
  else
    raise StandandError("Unable to configure AWS Cognito Client.  Exiting.")
  end
end

def configuration(yaml_file_name)
  storage_yml = Pathname.new(Rails.root.join('config', yaml_file_name))
  erb = ERB.new(storage_yml.read)
  configuration = YAML.safe_load(erb.result) || {}
  configuration.deep_symbolize_keys
rescue Errno::ENOENT
  puts "Missing configuration file #{yaml_file_name} in config"
  {}
end


SelfService.register_service(
  name: :cognito_client,
  client: cognito_client
)

SelfService.register_service(
  name: :storage_client,
  client: ActiveStorage::Service.configure(
    Rails.configuration.active_storage.service,
    configuration('storage.yml')
  )
)
