lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "baby_squeel/version"

Gem::Specification.new do |spec|
  spec.name          = "baby_squeel"
  spec.version       = BabySqueel::VERSION
  spec.authors       = ["Ray Zane"]
  spec.email         = ["ray@promptworks.com"]

  spec.summary       = "An expressive query DSL for Active Record 8.0+"
  spec.description   = "Squeel-like joining and where.has blocks for Active Record, including outer and " \
                       "polymorphic joins and attributes that resolve the alias of a joined table."
  spec.homepage      = "https://github.com/rocket-turtle/baby_squeel"
  spec.license       = "MIT"

  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.3"

  spec.files = Dir.glob("lib/**/*") + %w[README.md CHANGELOG.md LICENSE.txt baby_squeel.gemspec]

  spec.add_dependency "activerecord", ">= 8.0.4", "< 8.2"

  spec.add_development_dependency "bundler", "~> 4.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.10"
  spec.add_development_dependency "rubocop", "~> 1.0"
  spec.add_development_dependency "sqlite3", "~> 2.0"
end
