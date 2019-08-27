require 'net/http'
require 'json'

class JwksLoader
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

private

  def add_live_to_cache
    Rails.cache.fetch(@cache_key, expires_in: Rails.configuration.jwks_expiry) do
      Rails.logger.info "Loading JWKS from cognito..."
      response = Net::HTTP.get(URI("https://cognito-idp.#{region}.amazonaws.com/#{user_pool_id}/.well-known/jwks.json"))
      JSON.parse(response)
    end
  end

  def add_stub_to_cache
    Rails.cache.fetch(@cache_key, expires_in: Rails.configuration.jwks_expiry) do
      Rails.logger.info "Creating new JWKS for stubbing..."
      jwk_set = JSON::JWK::Set.new(keys: [JSON::JWK.new($cognito_jwt_private_key.public_key, kid: 2)])
      # to_json produces a JSON String which needs to be turned in to an object
      JSON.parse(jwk_set.to_json)
    end
  end

  def region
    Rails.application.secrets.aws_region
  end

  def user_pool_id
    Rails.application.secrets.cognito_user_pool_id
  end
end
