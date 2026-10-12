source "https://rubygems.org"

# Specify your gem's dependencies in baby_squeel.gemspec
gemspec

# AR picks the Active Record version to test against, for example AR='~> 8.0.4'
# or AR=main. Unset, the gemspec's range decides.
if ENV["AR"] == "main"
  gem "activerecord", github: "rails/rails"
elsif ENV["AR"]
  gem "activerecord", ENV["AR"]
end

# bin/console; irb leaves the default gems with Ruby 4.0
gem "irb", group: :development
