class CognitoStubClient
  # TODO Turn stub_user_hash into a JWT token which
  # can be returned by the stub client
  def self.stub_user_hash(role:, email_domain: "test.com")
    { username: '00000000-0000-0000-0000-000000000000', user_attributes:
      [
        { name: 'sub', value: '00000000-0000-0000-0000-000000000000' },
        { name: 'custom:roles', value: role },
        { name: 'email_verified', value: 'true' },
        { name: 'phone_number_verified', value: 'true' },
        { name: 'phone_number', value: '+447000000000' },
        { name: 'given_name', value: 'Daenerys' },
        { name: 'family_name', value: 'Targaryen' },
        { name: 'email', value: "daenerys.targaryen@#{email_domain}" }
      ],
    preferred_mfa_setting: 'SOFTWARE_TOKEN_MFA',
    user_mfa_setting_list: %w[SOFTWARE_TOKEN_MFA] }
  end

  def self.stub_gds_user_hash
    self.stub_user_hash(role: ROLE::GDS, email_domain: "digital.cabinet-office.gov.uk")
  end

  def self.setup_user(user_hash)
    SelfService.service(:cognito_client).stub_responses(:get_user, user_hash)
  end

  def self.update_user(role:, email_domain: "test.com")
    user_hash = stub_user_hash(role: role, email_domain: email_domain)
    setup_user(user_hash)
  end

  def self.setup_stubs
    SelfService.service(:cognito_client).stub_responses(
      :initiate_auth,
      challenge_name: nil, authentication_result: { access_token: "valid-token" }
    )
    SelfService.service(:cognito_client).stub_responses(
      :respond_to_auth_challenge,
      challenge_name: nil, authentication_result: { access_token: "valid-token" }
    )
    setup_user(stub_gds_user_hash)
  end

  def self.stub_client
    Aws::CognitoIdentityProvider::Client.new(stub_responses: true)
  end

  def self.switch_to_cognito
    # Exit if we are already a cognito client
    return false unless SelfService.service(:cognito_stub)
    # Exit if there isn't a cognito client available to switch to
    return false unless SelfService.service_present?(:real_client)

    real_client = SelfService.service(:real_client)
    SelfService.register_service(name: :cognito_client, client: real_client)
    SelfService.register_service(name: :cognito_stub, client: false)
  end

  def self.switch_to_stub
    # Exit if we are in production we don't want a stub in production
    return false if Rails.env.production?
    # Exit if we're already a stub client
    return false if SelfService.service(:cognito_stub)

    real_client = SelfService.service(:cognito_client)
    SelfService.register_service(name: :real_client, client: real_client)
    SelfService.register_service(name: :cognito_client, client: stub_client)
    setup_stubs
    SelfService.register_service(name: :cognito_stub, client: true)
  end
end
