Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.

  if Rails.root.join('tmp', 'caching-dev.txt').exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store

    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :memory_store
  end

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = false

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  config.aws_region = ENV['AWS_REGION']

  config.hub_environments = {
    'development': {
      'bucket': 'development-bucket',
      'hub_config_host': 'http://localhost:50240',
      'secure_header': 'false'
    }
  }

  config.cognito_aws_access_key_id = ENV['COGNITO_AWS_ACCESS_KEY_ID']
  config.cognito_aws_secret_access_key = ENV['COGNITO_AWS_SECRET_ACCESS_KEY']
  config.cognito_client_id = ENV['AWS_COGNITO_CLIENT_ID']
  config.cognito_user_pool_id = ENV['AWS_COGNITO_USER_POOL_ID']

  # Increase the timeout for devs
  config.session_expiry = 120.minutes
  config.session_inactivity = 120.minutes

  # To seed Cognito and check data integrity (uncomment, if needed to be run):
   config.after_initialize do
  #   require 'auth/initial_seeder'
  #   InitialSeeder.new
  #
     require 'data/integrity_checker'
     IntegrityChecker.new
   end

  config.after_initialize do
    require 'api/hub_config_api'
    HUB_CONFIG_API = HubConfigApi.new
  end

  config.scheduler_polling_interval =  ENV.fetch('SCHEDULER_POLLING_INTERVAL','5s')
  config.notify_key = ENV.fetch('NOTIFY_KEY', 'test-11111111-1111-1111-1111-111111111111-11111111-1111-1111-1111-111111111111')
  config.app_url = ENV.fetch('APP_URL', 'localhost:3000')
end
