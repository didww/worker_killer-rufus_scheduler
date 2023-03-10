# frozen_string_literal: true

module WorkerKiller
  module RufusScheduler
    # Base class for registration rufus process killer.
    class BaseLimiter
      def self.register(**kwargs)
        new(**kwargs).register
      end

      attr_reader :scheduler, :frequency, :killer, :limiter, :timeout, :job_filter

      # @param scheduler [Rufus::Scheduler]
      # @param limiter [#check,#started_at]
      # @param frequency [Integer,nil] run after each job if frequency is nil
      # @param timeout [Integer]
      # @param logger [Logger,nil]
      # @param job_filter [Proc,nil] when frequency=nil, used to select which jobs should be counted
      def initialize(scheduler:, limiter:, frequency: 30, timeout: 60, logger: nil, job_filter: nil)
        ::WorkerKiller.configure do |config|
          # Setting up logger for both limiter and killer
          config.logger = logger unless logger.nil?
          # We use wait instead of attempts, because attempts does not work for rufus.
          # rufus can either kill active jobs now or wait N seconds until they finished.
          config.quit_attempts = 1
          config.term_attempts = 0
        end

        @scheduler = scheduler
        @frequency = frequency&.to_i
        @timeout = timeout.to_i
        @killer = ::WorkerKiller::Killer::RufusScheduler.new
        @limiter = limiter
        @job_filter = job_filter
      end

      def register
        if frequency
          register_every_job
        else
          register_post_run_job
        end
      end

      def run_check
        killer.kill(limiter.started_at, scheduler: scheduler, timeout: timeout) if limiter.check
      end

      def check_after_job?(job, trigger_time)
        return true if job_filter.nil?

        job_filter.call(job, trigger_time)
      end

      private

      def register_every_job
        scheduler.every(frequency) { run_check }
      end

      def register_post_run_job
        limiter = self
        scheduler.define_singleton_method(:on_post_trigger) do |job, trigger_time|
          limiter.run_check if limiter.check_after_job?(job, trigger_time)
        end
      end
    end
  end
end
