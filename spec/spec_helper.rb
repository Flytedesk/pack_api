# frozen_string_literal: true

require "bundler/setup"
require "pack_api"
require "rspec/collection_matchers"

# Initialize Rails application with ActiveRecord and ActiveStorage
require_relative "support/rails_app"

# Set up database schema
require_relative "support/schema"

# Load test models
require_relative "support/models/author"
require_relative "support/models/comment"
require_relative "support/models/blog_post"

# Load test value objects
require_relative "support/public/author_type"
require_relative "support/public/comment_type"
require_relative "support/public/blog_post_type"

# Load test API mappings
require_relative "support/api/author_attribute_map"
require_relative "support/api/comment_attribute_map"
require_relative "support/api/blog_post_attribute_map"
require_relative "support/api/test_attribute_map_registry"
require_relative "support/api/test_value_object_factory"

# Load rspec_config
require_relative "rspec_config"

# Require other support files (but skip the ones we already loaded)
Dir[File.join(__dir__, "support", "**", "*.rb")].sort.each do |f|
  next if f.include?('rails_app.rb') || f.include?('schema.rb') || f.include?('models/')
  require f
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.around(:each) do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end
