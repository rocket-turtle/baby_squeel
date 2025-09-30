require 'bundler/setup'
require 'simplecov'
require 'pry'
require 'byebug'

SimpleCov.start { add_filter 'spec/' }

require 'baby_squeel'
require 'support/schema'
require 'support/models'
require 'support/matchers'
require 'support/factories'
require 'support/query_tracker'
require 'support/polyamorous_helper'

if ActiveSupport.respond_to?(:deprecator)
  ActiveSupport.deprecator.behavior = :raise
  ActiveRecord.deprecator.behavior = :raise
else
  ActiveSupport::Deprecation.behavior = :raise
end

RSpec.configure do |config|
  config.include Factories
  config.include QueryTracker
  config.include PolyamorousHelper, :polyamorous

  config.filter_run focus: true
  config.default_formatter = config.files_to_run.one? ? :doc : :progress
  config.run_all_when_everything_filtered = true
  config.example_status_persistence_file_path = 'tmp/spec-results.log'

  config.before :suite do
    puts "\nRunning with ActiveRecord #{ActiveRecord::VERSION::STRING}"
  end
end
