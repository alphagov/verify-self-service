Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raises error for missing translations
  config.action_view.raise_on_missing_translations = true

  config.middleware.use RackSessionAccess::Middleware

  config.aws_region = ENV['AWS_REGION']

  config.hub_environments = JSON.parse("{
    \"production\": {\"bucket\": \"production-bucket\", \"hub_config_host\": \"http://config-service.test\", \"secure_header\": \"false\"},
    \"integration\": {\"bucket\": \"integration-bucket\", \"hub_config_host\": \"http://config-service.test\", \"secure_header\": \"true\"},
    \"staging\": {\"bucket\": \"staging-bucket\", \"hub_config_host\": \"http://config-service.test\", \"secure_header\": \"false\"},
    \"test\": {\"bucket\": \"test-bucket\", \"hub_config_host\": \"http://config-service.test\", \"secure_header\": \"false\"}
  }")

  config.authentication_header = 'secure-header-value'

  config.cognito_aws_access_key_id = ENV['COGNITO_AWS_ACCESS_KEY_ID']
  config.cognito_aws_secret_access_key = ENV['COGNITO_AWS_SECRET_ACCESS_KEY']
  config.cognito_client_id = ENV['AWS_COGNITO_CLIENT_ID']
  config.cognito_user_pool_id = ENV['AWS_COGNITO_USER_POOL_ID']
  config.scheduler_polling_interval =  ENV.fetch('SCHEDULER_POLLING_INTERVAL','0.5s')
  config.notify_key = 'test-11111111-1111-1111-1111-111111111111-11111111-1111-1111-1111-111111111111'
  config.app_url = 'www.test.com'

  config.after_initialize do
    require 'polling/scheduler'
    SCHEDULER = Polling::Scheduler.new

    require 'api/hub_config_api'
    HUB_CONFIG_API = HubConfigApi.new

    require 'polling/dev_cert_status_updater'
    CERT_STATUS_UPDATER = DevCertStatusUpdater.new
  end
end
