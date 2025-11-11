# frozen_string_literal: true

require_relative "lib/pack_api/version"

Gem::Specification.new do |spec|
  spec.name = "pack_api"
  spec.version = PackAPI::VERSION
  spec.authors = ["Flytedesk"]
  spec.email = ["dev@flytedesk.com"]

  spec.summary = "Building blocks for implementing APIs around domain models"
  spec.description = <<~DESC
    Building blocks used to implement an API around a domain pack. Includes tools for data transformation, 
    discoverable filters, building ActiveRecord queries from API arguments, breaking query results across pages, and
    fetching data from API endpoints.
  DESC
  spec.homepage = "https://github.com/flytedesk/pack_api"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/flytedesk/pack_api/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir[
    "lib/**/*.rb",
    "LICENSE.txt",
    "README.md",
    "CHANGELOG.md"
  ]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_runtime_dependency "activerecord", ">= 7.0", "< 9.0"
  spec.add_runtime_dependency "brotli", "~> 0.5"
  spec.add_runtime_dependency "dry-types", ">= 1.8", "< 2.0"
  spec.add_runtime_dependency "dry-struct", ">= 1.6", "< 2.0"

  # Development dependencies
  spec.add_development_dependency "rspec", ">= 3.12", "< 4.0"
  spec.add_development_dependency "rspec-collection_matchers", "~> 1.2"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "sqlite3", ">= 1.4", "< 2.0"
  spec.add_development_dependency "rack", "~> 2.0"
  spec.add_development_dependency "rails", ">= 7.0", "< 9.0"
end
