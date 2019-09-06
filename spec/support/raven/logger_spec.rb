require 'spec_helper'
require 'logger'
require 'support/raven/logger'
require 'action_controller/metal/exceptions'
require 'raven'

describe Support::Raven::Logger do
  let(:logger) { Support::Raven::Logger.new }

  context "#error" do
    it 'will send exceptions to sentry' do
      error = StandardError.new
      expect(Raven).to receive(:capture_exception).with(error)
      logger.error(error)
    end

    it 'will not send routing exceptions to sentry' do
      error = ActionController::RoutingError.new(nil)
      expect(Raven).not_to receive(:capture_exception).with(error)
      logger.error(error)
    end

    it 'will not send whitespace to sentry' do
      error = "  "
      expect(Raven).to_not receive(:capture_exception).with(error)
      logger.error(error)
    end

    it 'will not send routing error messages to sentry' do
      error = "ActionController::RoutingError (No route matches [GET] \"/favicon.ico\")"
      expect(Raven).to_not receive(:capture_exception).with(error)
      logger.error(error)
    end
  end
end
