require 'support/raven/logger'

if Rails.env.production?
  Rails.logger.extend(ActiveSupport::Logger.broadcast(Support::Raven::Logger.new))
end