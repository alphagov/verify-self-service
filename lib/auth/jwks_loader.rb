require 'net/http'
require 'json'

class JwksLoader
  attr_reader :jwk
  def initialize(live = true)
    @cache_key = "#{Time.now.to_formatted_s(:number)}/jwks"
    if live
      add_live_to_cache
    else
      add_stub_to_cache
    end
  end

  def fetch
    Rails.cache.fetch(@cache_key)
  end

  def call(_options)
    self.fetch
  end

private

  def add_live_to_cache
    Rails.cache.fetch(@cache_key, expires_in: Rails.configuration.jwks_cache_expiry) do
      Rails.logger.info "Loading JWKS from cognito..."
      response = Net::HTTP.get(URI("https://cognito-idp.#{region}.amazonaws.com/#{user_pool_id}/.well-known/jwks.json"))
      json = JSON.parse(response)
      { keys: json.fetch('keys').map { |data| HashWithIndifferentAccess.new(data) } }
    end
  end

  def add_stub_to_cache
    Rails.cache.fetch(@cache_key, expires_in: Rails.configuration.jwks_cache_expiry) do
      Rails.logger.info "Creating new JWKS for stubbing..."
      @jwk = JWT::JWK.new($cognito_jwt_private_key)
      { keys: [@jwk.export] }
    end
  end

  def region
    Rails.configuration.aws_region
  end

  def user_pool_id
    Rails.configuration.cognito_user_pool_id
  end
end