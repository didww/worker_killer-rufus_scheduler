# frozen_string_literal: true

module WorkerKiller
  module RufusScheduler
    # Register rufus process killer by RAM usage.
    class JobsLimiter < ::WorkerKiller::RufusScheduler::BaseLimiter
      # @param scheduler [Rufus::Scheduler]
      # @param limiter_kwargs [Hash]
      # @param timeout [Integer]
      # @param logger [Logger,nil]
      # @param job_filter [Proc,nil] used to select which jobs should be counted
      def initialize(scheduler:, timeout:, logger: nil, job_filter: nil, **limiter_kwargs)
        limiter = ::WorkerKiller::CountLimiter.new(**limiter_kwargs)
        super(
          scheduler: scheduler,
          frequency: nil,
          timeout: timeout,
          limiter: limiter,
          logger: logger,
          job_filter: job_filter
        )
      end
    end
  end
end
