# frozen_string_literal: true

module WorkerKiller
  module Killer
    # Gracefully kills rufus scheduler.
    class RufusScheduler < ::WorkerKiller::Killer::Base
      # @param scheduler [Rufus::Scheduler]
      # @param timeout [Integer]
      def do_kill(sig, pid, alive_sec, scheduler:, timeout:, **_params)
        if sig == :KILL
          logger.error { "#{self} force to #{sig} self (pid: #{pid}) alive: #{alive_sec} sec" }
          scheduler.shutdown(:kill)
          return
        end

        logger.warn { "#{self} run #{sig} self (pid: #{pid}) alive: #{alive_sec} sec, timeout: #{timeout} sec" }
        scheduler.shutdown(wait: timeout)
      end
    end
  end
end
