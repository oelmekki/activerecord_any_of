# frozen_string_literal: true

source 'https://rubygems.org'

gemspec path: File.expand_path(__dir__)

if ENV['ANY_OF_RAILS_6'] == 'true'
  gem 'activerecord', '~> 6'
else
  gem 'activerecord', '~> 7'
end

gem 'database_cleaner'
gem 'pry'
gem 'rake', '>= 12.3.3'
gem 'rspec'
gem 'rspec-rails'
gem 'rubocop'
gem 'rubocop-rake'
gem 'rubocop-rspec'
gem 'simplecov'
gem 'sqlite3'
