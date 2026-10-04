require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

namespace :snapshots do
  desc "Run the suite and drop snapshot keys no example read; keeps the variants of other Active Record versions"
  task :prune do
    sh({ "PRUNE_SNAPSHOTS" => "1" }, "bundle exec rspec")
  end
end

task default: :spec
