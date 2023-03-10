# frozen_string_literal: true

require_relative 'rufus_scheduler/version'
require 'worker_killer'
require_relative 'killer/rufus_scheduler'
require_relative 'rufus_scheduler/base_limiter'
require_relative 'rufus_scheduler/oom_limiter'
require_relative 'rufus_scheduler/jobs_limiter'

module WorkerKiller
  # Worker killer for Rufus::Scheduler.
  module RufusScheduler
  end
end
