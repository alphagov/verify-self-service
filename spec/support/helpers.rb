require 'support/helpers/session_helpers'
require_relative 'storage_support'
RSpec.configure do |config|
  config.include System::SessionHelpers, type: :system
  config.include StorageSupport, type: :system
end
