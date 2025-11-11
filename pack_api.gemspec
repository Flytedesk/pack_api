# frozen_string_literal: true

require_relative "lib/pack_api/version"

Gem::Specification.new do |spec|
  spec.name = "pack_api"
  spec.version = PackAPI::VERSION
  spec.authors = ["Flytedesk"]
  spec.email = ["dev@flytedesk.com"]

  spec.summary = "Building blocks for implementing APIs around domain models"
  spec.description = <<~DESC
    Building blocks used to implement an API around a domain pack. Includes:
    - elements for passing data out of the API
    - elements for describing the filters supported by query endpoints in the API
    - elements for building the mapping between domain models and API models
    - elements for building the query endpoints themselves, based on user inputs (sort, filter, pagination)
    - elements for retrieving multiple pages of data from other query endpoints
  DESC
  spec.homepage = "https://github.com/flytedesk/pack_api"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/flytedesk/pack_api"
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
  spec.add_dependency "activerecord", "~> 7.0"
  spec.add_dependency "brotli", "~> 0.5"
  spec.add_dependency "dry-types", "~> 1.8"
  spec.add_dependency "dry-struct", "~> 1.6"

  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rspec-collection_matchers", "~> 1.2"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "sqlite3", "~> 1.4"
  spec.add_development_dependency "activesupport", "~> 7.0"
  spec.add_development_dependency "activemodel", "~> 7.0"
  spec.add_development_dependency "rack", "~> 2.0"
  spec.add_development_dependency "rails", "~> 7.0" # For ActiveStorage in tests
end
