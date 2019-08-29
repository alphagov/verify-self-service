class CognitoStubClient
  # TODO Turn stub_user_hash into a JWT token which
  # can be returned by the stub client
  def self.stub_user_hash(role:, email_domain: "test.com", groups: %w[devs])
    {
      'sub' => '00000000-0000-0000-0000-000000000000',
      'custom:roles' => role,
      'cognito:groups' => groups,
      'email_verified' => true,
      'phone_number_verified' => true,
      'cognito:username' => '00000000-0000-0000-0000-000000000000',
      'given_name' => 'Daenerys',
      'cognito:roles' => ['arn:aws:iam::000000000000:role/daenerys.targaryen-read-only'],
      'event_id' => '00000000-0000-0000-0000-000000000000',
      'token_use' => 'id',
      'auth_time' => Time.now,
      'phone_number' => '+447000000000',
      'exp' => 1.week.from_now.to_i,
      'iat' => Time.now.to_i,
      'family_name' => 'Targaryen',
      'email' => "daenerys.targaryen@#{email_domain}",
      'mfa' => true
    }
  end

  def self.stub_gds_user_hash
    self.stub_user_hash(role: ROLE::GDS, email_domain: TEAMS::GDS_EMAIL_DOMAIN)
  end

  def self.setup_user(user_hash)
    SelfService.service(:cognito_client).stub_responses(
      :respond_to_auth_challenge,
      challenge_name: nil, authentication_result: { access_token: 'valid-token', id_token: user_hash_to_jwt(user_hash) }
    )
    SelfService.service(:cognito_client).stub_responses(
      :initiate_auth,
      challenge_name: nil,
      session: "",
      challenge_parameters: { "FRIENDLY_DEVICE_NAME" => "Authy", "USER_ID_FOR_SRP" => "" },
      authentication_result: { access_token: 'valid-token', id_token: user_hash_to_jwt(user_hash) }
    )
  end

  def self.user_hash_to_jwt(user_hash)
    payload = user_hash
    headers = { kid: SelfService.service(:jwks).jwk.kid }
    JWT.encode(payload, SelfService.service(:jwks).jwk.keypair, 'RS256', headers)
  end

  def self.update_user(role:, email_domain: "test.com", groups: %w[test])
    user_hash = stub_user_hash(role: role, email_domain: email_domain, groups: groups)
    setup_user(user_hash)
  end

  def self.setup_stubs
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
    jwks = JwksLoader.new
    SelfService.register_service(name: :cognito_client, client: real_client)
    SelfService.register_service(name: :jwks, client: jwks)
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
    register_jwks
    setup_stubs
    SelfService.register_service(name: :cognito_stub, client: true)
  end

  def self.register_jwks
    $cognito_jwt_private_key = OpenSSL::PKey::RSA.generate(2048)
    jwks_loader = JwksLoader.new(false)
    SelfService.register_service(name: :jwks, client: jwks_loader)
  end
end
