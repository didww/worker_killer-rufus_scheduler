# frozen_string_literal: true

module WorkerKiller
  module RufusScheduler
    # Register rufus process killer by RAM usage.
    class OOMLimiter < ::WorkerKiller::RufusScheduler::BaseLimiter
      # @param scheduler [Rufus::Scheduler]
      # @param limiter_kwargs [Hash]
      # @param frequency [Integer]
      # @param timeout [Integer]
      # @param logger [Logger,nil]
      def initialize(scheduler:, frequency:, timeout:, logger: nil, **limiter_kwargs)
        # frequency parameter used to set how often check should be run, instead of check_cycle.
        limiter = ::WorkerKiller::MemoryLimiter.new(check_cycle: 1, **limiter_kwargs)
        super(scheduler: scheduler, frequency: frequency, timeout: timeout, limiter: limiter, logger: logger)
      end
    end
  end
end
