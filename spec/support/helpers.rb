require 'support/helpers/session_helpers'
RSpec.configure do |config|
  config.include System::SessionHelpers, type: :system
end
