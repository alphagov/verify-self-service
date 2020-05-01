require 'rufus-scheduler'
module Polling
  class Scheduler
    attr_reader :rufus_scheduler, :job, :time, :opts
    DEFAULT_TIMEOUT = '100.0s'.freeze
    DEFAULT_NUMBER_POLLS = 8
    # MAX_WORK_THREADS is set to a value substantially lower than db connection pool, so rufus is limited to creating only 2 connections from the pool
    MAX_WORK_THREADS = 2
    def initialize(opts = { overlap: false, timeout: DEFAULT_TIMEOUT, times: DEFAULT_NUMBER_POLLS, frequency: Rails.configuration.scheduler_polling_interval })
      @opts = opts
      @rufus_scheduler ||= Rufus::Scheduler.new(frequency: opts[:frequency], max_work_threads: MAX_WORK_THREADS)
      @rufus_scheduler.stderr = StringIO.new
    end

    def mode(mode, time = Rails.configuration.scheduler_polling_interval)
    # @mode is any of kind of rufus-scheduler job i.e in, at, every, interval and cron jobs
      @mode = mode
      @time = time
      self
    end

    def perform(action = -> {})
      #rufus starts a new thread for every job, active record does not share connection between threads
      # below allows the connection in the rufus thread to be released back to the pool when the thread is done
      ActiveRecord::Base.connection_pool.with_connection do
        @job = @rufus_scheduler.method("schedule_#{@mode}")
                              .call(time, **opts, &action)
      end
      self
    rescue Rufus::Scheduler::NotRunningError => e
      rufus_scheduler.on_error(rufus_scheduler, e)
      Rails.logger.error(e.message.to_s)
    rescue NameError => e
      rufus_scheduler.on_error(rufus_scheduler, e)
      Rails.logger.error("#{e}, Expected symbol or string for scheduler i.e in, at, every, interval or cron")
    end

    def action_result
      job.handler.call
    end

    def until(test)
      unschedule if test
    end

    def stderr
      rufus_scheduler.stderr
    end

  private

    def unschedule
      rufus_scheduler.unschedule(job)
      job.kill
    end
  end
end
