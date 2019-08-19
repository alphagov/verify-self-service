class CognitoChooser
  def initialize
    Rails.logger.info "Loading cognito..."
    if Rails.env.production?
      Rails.logger.info "choosing production client"
      register_production_client
    elsif aws_access_key.present? && aws_secret_key.present? && Rails.env != 'test'
      Rails.logger.info "choosing dev client"
      register_dev_client
    elsif %w(test development).include? Rails.env
      Rails.logger.info "choosing stub client"
      register_stub_client
      CognitoStubClient.setup_stubs
    else
      raise StandandError('Unable to configure AWS Cognito Client.  Exiting.')
    end
  end

  def aws_access_key
    Rails.application.secrets.cognito_aws_access_key_id
  end

  def aws_secret_key
    Rails.application.secrets.cognito_aws_secret_access_key
  end

  def register_client(client:, is_stub: true)
    SelfService.register_service(name: :cognito_stub, client: is_stub)
    SelfService.register_service(name: :real_client, client: client) unless is_stub
    SelfService.register_service(name: :cognito_client, client: client)
  end

  def register_production_client
    register_client(
      client: Aws::CognitoIdentityProvider::Client.new,
      is_stub: false
    )
  end

  def register_dev_client
    register_client(client: Aws::CognitoIdentityProvider::Client.new(
      region: Rails.application.secrets.aws_region,
      access_key_id: aws_access_key,
      secret_access_key: aws_secret_key
    ), is_stub: false)
  end

  def register_stub_client
    Rails.application.secrets.cognito_client_id = SecureRandom.uuid
    Rails.application.secrets.cognito_user_pool_id = SecureRandom.uuid
    register_client(
      client: CognitoStubClient.stub_client
    )
  end
end
