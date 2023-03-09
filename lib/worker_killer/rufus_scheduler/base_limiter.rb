# frozen_string_literal: true

module WorkerKiller
  module RufusScheduler
    # Base class for registration rufus process killer.
    class BaseLimiter
      def self.register(**kwargs)
        new(**kwargs).register
      end

      attr_reader :scheduler, :frequency, :killer, :limiter, :timeout

      # @param scheduler [Rufus::Scheduler]
      # @param limiter [#check,#started_at]
      # @param frequency [Integer]
      # @param timeout [Integer]
      # @param logger [Logger,nil]
      def initialize(scheduler:, limiter:, frequency: 30, timeout: 60, logger: nil)
        ::WorkerKiller.configure do |config|
          # Setting up logger for both limiter and killer
          config.logger = logger unless logger.nil?
          # We use wait instead of attempts, because attempts does not work for rufus.
          # rufus can either kill active jobs now or wait N seconds until they finished.
          config.quit_attempts = 1
          config.term_attempts = 0
        end

        @scheduler = scheduler
        @frequency = frequency.to_i
        @timeout = timeout.to_i
        @killer = ::WorkerKiller::Killer::RufusScheduler.new
        @limiter = limiter
      end

      def register
        scheduler.every(frequency) do
          killer.kill(limiter.started_at, scheduler: scheduler, timeout: timeout) if limiter.check
        end
      end
    end
  end
end
