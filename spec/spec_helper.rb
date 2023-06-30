# frozen_string_literal: true

plugin_test_dir = File.dirname(__FILE__)

require 'bundler'
require 'simplecov'

SimpleCov.start
SimpleCov.minimum_coverage 95 # we can't cover rails-6 code when running on rails-7, and reversibly

require 'logger'
require 'rails/all'
require 'active_record'
Bundler.require :default, :development
require 'rspec/rails'
require 'pry'

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Base.logger = Logger.new("#{plugin_test_dir}/debug.log")
ActiveRecord::Migration.verbose = false
load(File.join(plugin_test_dir, 'support', 'schema.rb'))

require 'activerecord_any_of'
require 'support/models'

require 'action_controller'
require 'database_cleaner'
RSpec.configure do |config|
  config.fixture_path = "#{plugin_test_dir}/fixtures"
  config.use_transactional_fixtures = true
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
end
