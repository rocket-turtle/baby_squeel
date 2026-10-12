require "bundler/setup"
require "byebug"

if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start do
    enable_coverage :branch
    skip "spec/"
  end
end

require "baby_squeel"
require "support/schema"
require "support/models"
require "support/matchers"
require "support/factories"

ActiveSupport.deprecator.behavior = :raise
ActiveRecord.deprecator.behavior = :raise

RSpec.configure do |config|
  config.include Factories

  config.filter_run_when_matching :focus
  config.default_formatter = config.files_to_run.one? ? :doc : :progress
  config.example_status_persistence_file_path = "tmp/spec-results.log"

  config.before :suite do
    puts "\nRunning with ActiveRecord #{ActiveRecord::VERSION::STRING}"
  end
end
