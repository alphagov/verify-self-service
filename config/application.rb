require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
# require "action_cable/engine"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module VerifySelfService
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    # Don't generate system test files.
    config.generators.system_tests = nil
    # explicitly override ActiveRecord primary_key type from id to use uuid
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end
    # by default rails wraps invalid inputs with <div class="field_with_errors">
    # we have our own way of styling errors, so we don't need this behaviour:
    config.action_view.field_error_proc = Proc.new { |html_tag| html_tag }

    config.i18n.default_locale = :en

    # User will be timed out after 90 minutes regardless of activity
    config.session_expiry = 90.minutes

    # User will be timed out after 15 minutes of inactivity
    config.session_inactivity = 15.minutes

    # The cache reload time for the JWKS file from amazon
    config.jwks_cache_expiry = 1.hour
  end
end
