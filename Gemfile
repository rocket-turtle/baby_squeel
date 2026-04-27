source "https://rubygems.org"

# Specify your gem's dependencies in baby_squeel.gemspec
gemspec

if ENV["AR"] == "main"
  gem "activerecord", github: "rails/rails"
else
  gem "activerecord", ENV["AR"]
end

gem "sqlite3", ">= 1.4"

group :test do
  gem "byebug"
  gem "pry"
  gem "simplecov"
end
