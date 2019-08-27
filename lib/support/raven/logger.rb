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
        def write(msg = nil)
          ::Raven.capture_exception(msg) unless msg.nil?
        end
      end
    end
  end
end
