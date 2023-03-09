# frozen_string_literal: true

require 'worker_killer/rufus_scheduler'
if ENV['COVERAGE'] == 'true'
  require 'simplecov'
  require 'simplecov-cobertura'
  SimpleCov.start do
    load_profile 'test_frameworks'
    enable_coverage :branch
    formatter SimpleCov::Formatter::CoberturaFormatter
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
