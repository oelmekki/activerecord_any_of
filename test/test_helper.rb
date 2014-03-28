plugin_test_dir = File.dirname(__FILE__)

require 'rubygems'
require 'bundler/setup'

require 'rails'
require 'active_record'
require 'activerecord_any_of'

require "rails/test_help"
require 'combustion/database'
require 'database_cleaner'

require 'pry'
require 'logger'
require 'yaml'
require 'erb'

require 'support/models'

ActiveRecord::Base.logger = Logger.new(plugin_test_dir + "/debug.log")

ActiveRecord::Base.configurations = YAML::load(ERB.new(IO.read(plugin_test_dir + "/db/database.yml")).result)
ActiveRecord::Base.establish_connection(ENV["DB"] ||= "sqlite3mem")
ActiveRecord::Migration.verbose = false

Combustion::Database.create_database(ActiveRecord::Base.configurations[ENV["DB"]])
load(File.join(plugin_test_dir, "db", "schema.rb"))

ActiveSupport::TestCase.fixture_path = "#{plugin_test_dir}/fixtures"
ActiveSupport::TestCase.use_transactional_fixtures = true
ActiveSupport::TestCase.teardown do
  unless /sqlite/ === ENV['DB']
    Combustion::Database.drop_database(ActiveRecord::Base.configurations[ENV['DB']])
  end
end
