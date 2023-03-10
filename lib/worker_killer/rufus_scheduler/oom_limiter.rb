# frozen_string_literal: true

module WorkerKiller
  module RufusScheduler
    # Register rufus process killer by RAM usage.
    class OOMLimiter < ::WorkerKiller::RufusScheduler::BaseLimiter
      # @param scheduler [Rufus::Scheduler]
      # @param limiter_kwargs [Hash]
      # @param frequency [Integer,nil]
      # @param timeout [Integer]
      # @param logger [Logger,nil]
      # @param job_filter [Proc,nil] when frequency=null, used to select which jobs should be counted
      def initialize(scheduler:, frequency:, timeout:, logger: nil, job_filter: nil, **limiter_kwargs)
        # when frequency parameter used to set how often check should be run, check_cycle is not needed.
        limiter = ::WorkerKiller::MemoryLimiter.new(check_cycle: 1, **limiter_kwargs)
        super(
          scheduler: scheduler,
          frequency: frequency,
          timeout: timeout,
          limiter: limiter,
          logger: logger,
          job_filter: job_filter
        )
      end
    end
  end
end
