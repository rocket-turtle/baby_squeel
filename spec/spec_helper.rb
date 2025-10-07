require 'bundler/setup'
require 'simplecov'
require 'byebug'

SimpleCov.start { add_filter 'spec/' }

require 'baby_squeel'
require 'support/schema'
require 'support/models'
require 'support/matchers'
require 'support/factories'
require 'support/polyamorous_helper'

ActiveSupport.deprecator.behavior = :raise
ActiveRecord.deprecator.behavior = :raise

RSpec.configure do |config|
  config.include Factories
  config.include PolyamorousHelper, :polyamorous

  config.filter_run focus: true
  config.default_formatter = config.files_to_run.one? ? :doc : :progress
  config.run_all_when_everything_filtered = true
  config.example_status_persistence_file_path = 'tmp/spec-results.log'

  config.before :suite do
    puts "\nRunning with ActiveRecord #{ActiveRecord::VERSION::STRING}"
  end
end
