require "net/http"
require "json"

class JwksLoader
  def initialize
    @cache_key = "#{Time.now.to_formatted_s(:number)}/jwks"
    fetch_or_update
  end

  def call(_options)
    fetch_or_update
  end

private

  def fetch_or_update
    Rails.logger.debug "Initial Cache store information: #{Rails.cache.inspect}"

    jwks = Rails.cache.fetch(@cache_key, expires_in: Rails.configuration.jwks_cache_expiry) do
      Rails.logger.info "Loading JWKS from cognito..."
      Rails.logger.info "Fetching JWKS from: \"https://cognito-idp.#{region}.amazonaws.com/#{user_pool_id}/.well-known/jwks.json\""
      response = Net::HTTP.get(URI("https://cognito-idp.#{region}.amazonaws.com/#{user_pool_id}/.well-known/jwks.json"))
      Rails.logger.debug "Response from cognito #{response}"
      json = JSON.parse(response)
      { keys: json.fetch("keys").map { |data| HashWithIndifferentAccess.new(data) } }
    end
    Rails.logger.debug "Populated Cache store information: #{Rails.cache.inspect}"
    # Don't remove this as the debug statement above will return true instead
    jwks
  end

  def region
    Rails.configuration.aws_region
  end

  def user_pool_id
    Rails.configuration.cognito_user_pool_id
  end
end
