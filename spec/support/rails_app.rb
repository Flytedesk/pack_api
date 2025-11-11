# frozen_string_literal: true

require 'rails'
require 'active_record/railtie'
require 'active_storage/engine'

# Set Rails environment to test
ENV['RAILS_ENV'] = 'test'

# Minimal Rails application for testing
module Spec
  class TestApplication < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
    config.logger = Logger.new(nil) # Suppress logs during tests
    config.active_support.test_order = :random

    # Set the root path for the test application
    config.root = File.expand_path('../..', __dir__)

    # Point to the test database configuration
    config.paths['config/database'] = File.expand_path('config/database.yml', __dir__)

    # ActiveStorage configuration
    config.active_storage.service = :test
    config.active_storage.service_configurations = {
      test: {
        service: 'Disk',
        root: File.join(Dir.tmpdir, 'active_storage')
      }
    }
  end
end

# Initialize the Rails application
Spec::TestApplication.initialize!

# Establish the database connection
ActiveRecord::Base.establish_connection(:test)
