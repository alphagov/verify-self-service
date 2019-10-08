require 'support/raven/logger'

Rails.logger.extend(ActiveSupport::Logger.broadcast(Support::Raven::Logger.new))
