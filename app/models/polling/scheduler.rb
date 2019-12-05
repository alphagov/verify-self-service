require 'rufus-scheduler'
module Polling
  class Scheduler
    attr_reader :rufus_scheduler
    attr_reader :job
    DEFAULT_TIMEOUT = '30.0s'.freeze
    DEFAULT_NUMBER_POLLS = 30

    def initialize(opts = { overlap: false, timeout: DEFAULT_TIMEOUT, times: DEFAULT_NUMBER_POLLS })
      @opts = opts
      @rufus_scheduler ||= Rufus::Scheduler.new
      @rufus_scheduler.stderr = StringIO.new
    end

    def mode(mode, time = Rails.configuration.scheduler_polling_interval)
    # @mode is any of kind of rufus-scheduler job i.e in, at, every, interval and cron jobs
      @mode = mode
      @time = time
      self
    end

    def perform(action = -> {})
      @job = @rufus_scheduler.method("schedule_#{@mode}")
                            .call(@time, **@opts, &action)
      self
    rescue NameError => e
      Rails.logger.error("#{e}, Expected symbol or string for scheduler i.e in, at, every, interval or cron")
    end

    def action_result
      @job.handler.call
    end

    def until(test)
      stop if test
    end

    def stop
      @rufus_scheduler.stop
    end

    def stderr
      @rufus_scheduler.stderr
    end
  end
end
