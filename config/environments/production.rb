Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.

  # Define a content security policy
  # For further information see the following documentation
  # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, ENV["ASSET_HOST"]
    policy.img_src     :self, :data, ENV["ASSET_HOST"]
    policy.object_src  :none
    policy.script_src  :self, ENV["ASSET_HOST"]
    policy.style_src   :self, ENV["ASSET_HOST"]

    # Specify URI for violation reports
    # policy.report_uri "/csp-violation-report-endpoint"
  end

  config.content_security_policy_nonce_generator = -> request { SecureRandom.base64(16) }

  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # User will be timed out after 60 minutes regardless of activity
  # config.session_expiry = 60.minutes

  # User will be timed out after 15 minutes of inactivity
  # config.session_inactivity = 15.minutes

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :uglifier
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  # config.assets.compile = false

  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  config.action_controller.asset_host = ENV['ASSET_HOST']
  # Set the prefix to the correct asset folder for the host above
  config.assets.prefix = ENV['ASSET_PREFIX']
  # Turning digests off as the folder name (sha of the image) will serve the same purpose
  config.assets.digest = false

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Mount Action Cable outside main process or domain
  # config.action_cable.mount_path = nil
  # config.action_cable.url = 'wss://example.com/cable'
  # config.action_cable.allowed_request_origins = [ 'http://example.com', /http:\/\/example.*/ ]

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Skip the HTTPS redirect on the healtheck as it returns 301 Permanent Redirect
  config.ssl_options = { redirect: { exclude: -> request { request.path =~ /healthcheck/ } } }

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :debug

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # Use a different cache store in production.
  config.cache_store = :memory_store, { size: 32.megabytes }

  # Use a real queuing backend for Active Job (and separate queues per environment)
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "verify-self-service_#{Rails.env}"

  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = [I18n.default_locale]

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Use a different logger for distributed setups.
  # require 'syslog/logger'
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  config.aws_region = ENV.fetch('AWS_REGION')

  config.hub_environments = JSON.parse(ENV.fetch('HUB_ENVIRONMENTS'))

  config.cognito_client_id = ENV.fetch('AWS_COGNITO_CLIENT_ID')
  config.cognito_user_pool_id = ENV.fetch('AWS_COGNITO_USER_POOL_ID')

  config.notify_key = ENV.fetch('NOTIFY_KEY')

  config.app_url = ENV.fetch('APP_URL')

  # To seed Cognito
  # 1. Creates a GDS user if one doesn't exist
  # 2. Creates a GDS team and/or group if one doesn't exist
  # 3. Adds any users with GDS role AND GDS email address to the GDS group
  # NOTE: It's only neccessary to run this once in a new environment or after
  #       the Cognito instance has been wiped. However, it doesn't do any harm
  #       if it'll run on every startup
  config.after_initialize do
    require 'auth/initial_seeder'
    InitialSeeder.new unless ENV['DISABLE_COGNITO_SEEDING'].present?

    require 'data/integrity_checker'
    IntegrityChecker.new unless ENV['DISABLE_INTEGRITY_CHECKER'].present?

    require 'api/hub_config_api'
    HUB_CONFIG_API = HubConfigApi.new
  end

  config.scheduler_polling_interval =  ENV.fetch('SCHEDULER_POLLING_INTERVAL','5s')
  config.authentication_header = ENV.fetch('SELF_SERVICE_AUTHENTICATION_HEADER', nil)
end
