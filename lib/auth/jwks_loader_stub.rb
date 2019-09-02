class JwksLoaderStub < JwksLoader
  attr_reader :jwk
  def initialize(cognito_jwk_private_key)
    @jwk_private_key = cognito_jwk_private_key
    stub_jwk
  end

  def call(_options)
    stub_jwk
  end

private

  def stub_jwk
    @jwk = JWT::JWK.new(@jwk_private_key)
    { keys: [@jwk.export] }
  end
end
