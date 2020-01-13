require 'rufus-scheduler'
module Polling
  class Scheduler
    attr_reader :rufus_scheduler
    attr_reader :job
    DEFAULT_TIMEOUT = '100.0s'.freeze
    DEFAULT_NUMBER_POLLS = 12

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
    rescue Rufus::Scheduler::NotRunningError => e
      @rufus_scheduler.on_error(@rufus_scheduler, e)
      Rails.logger.error(e.message.to_s)
    rescue NameError => e
      @rufus_scheduler.on_error(@rufus_scheduler, e)
      Rails.logger.error("#{e}, Expected symbol or string for scheduler i.e in, at, every, interval or cron")
    end

    def action_result
      @job.handler.call
    end

    def until(test)
      unschedule if test
    end

    def stderr
      @rufus_scheduler.stderr
    end

  private

    def unschedule
      @rufus_scheduler.unschedule(@job)
    end
  end
end
