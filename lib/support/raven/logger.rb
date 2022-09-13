module Support
  module Raven
    class Logger < ::Logger
      def initialize
        super(nil)
        @formatter = RavenFormatter.new
        @logdev = RavenWriter.new
      end

      def add(severity, _exception = nil, _progname = nil, &block)
        super if severity >= ::Logger::ERROR
        true
      end

      # A Formatter which returns an exception if its there
      class RavenFormatter < ::Logger::Formatter
        # This method is invoked when a log event occurs
        def call(_severity, _timestamp, _progname, msg)
          case msg
          when ::Exception
            msg
          when String
            msg
          else
            msg.inspect
          end
        end
      end

      class RavenWriter
        UNLABELED_EVENT = '  '.freeze

        def write(msg = nil)
          unless msg.nil? || message_is_404?(msg)
            ::Raven.capture_exception(msg)
          end
        end

        def message_is_404?(message)
          message.is_a?(ActionController::RoutingError) ||
            (
              message.is_a?(String) &&
                (
                   message.include?('ActionController::RoutingError') ||
                   message == UNLABELED_EVENT
                 )
            )
        end
      end
    end
  end
end
