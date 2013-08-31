# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

dummy_app = ENV[ 'RAILS_VERSION' ] == '3' ? 'dummy_rails3' : 'dummy_rails4'

require File.expand_path("../#{dummy_app}/config/environment.rb",  __FILE__)
require "rails/test_help"

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Load fixtures from the engine
ActiveSupport::TestCase.fixture_path = File.expand_path("../fixtures", __FILE__)
