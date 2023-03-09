# frozen_string_literal: true

if ENV['COVERAGE'] == 'true'
  require 'simplecov'
  require 'simplecov-cobertura'
  SimpleCov.start do
    enable_coverage :branch
    formatter SimpleCov::Formatter::MultiFormatter.new(
      [
          SimpleCov::Formatter::CoberturaFormatter,
          SimpleCov::Formatter::HTMLFormatter
      ]
    )
    # formatter SimpleCov::Formatter::CoberturaFormatter
    filters.clear
    add_filter 'spec'
    add_filter 'bin'
    add_group 'Libraries', 'lib'
  end
end

require 'worker_killer/rufus_scheduler'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
