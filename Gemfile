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

group :test do
  gem "byebug"
  gem "pry"
  gem "simplecov"
end
