source 'https://rubygems.org'

# Specify your gem's dependencies in baby_squeel.gemspec
gemspec

case ENV.fetch('AR', 'latest')
when 'latest'
  gem 'activerecord'
when 'master'
  gem 'activerecord', github: 'rails/rails'
else
  gem 'activerecord', ENV['AR']
end

gem 'sqlite3', '>= 1.4'

gem 'bump'

group :test do
  gem 'pry'
  gem 'simplecov'
  gem 'byebug'
end
