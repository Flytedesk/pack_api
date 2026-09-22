# PackAPI

Building blocks for implementing APIs around domain models.

## Overview

PackAPI provides a comprehensive set of tools for building robust API layers on top of domain models. It includes utilities for:

- **Data transformation** - Elements for passing data out of the API
- **Filter definitions** - Elements for describing the filters supported by query endpoints in the API
- **Attribute mapping** - Elements for building the mapping between domain models and API models
- **Query building** - Elements for building query endpoints based on user inputs (sort, filter, pagination)
- **Batch operations** - Elements for retrieving multiple pages of data from other query endpoints

## Motivation

Separation of concerns and information hiding within the module. 

In order to separate the public interface from the (private) implementation of our subsystems (modules), we needed to 
create an API that did not depend on our ActiveRecord models. We chose to implement this separation using value objects
(built using dry-types, but could have been built using Ruby Data type). Beyond the API methods, the public interface
definition is then captured in the explicit attribute list of these value objects.

However, building the mapping between the domain models and the API value objects can be tedious and error-prone. We
created this gem to provide reusable building blocks to make this mapping easier to define and maintain.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pack_api'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install pack_api
```

## Requirements

- Ruby >= 3.0.0
- ActiveRecord >= 7.0
- dry-types ~> 1.8

## Features

### Mapping

The mapping module provides tools for transforming data between domain models and API representations:

- `AttributeMap` - Define bidirectional mappings between model and API attributes
- `AttributeMapRegistry` - Finds the attribute map for a model, by naming convention or explicit registration
- `ModelToAPIAttributesTransformer` - Transform model attributes to API format
- `APIToModelAttributesTransformer` - Transform API attributes to model format
- `ValueObjectFactory` - Create value objects from raw data

### Querying

Build flexible query interfaces with support for filtering, sorting, and pagination:

- `ComposableQuery` - Build complex queries from simpler components
- `CollectionQuery` - Query ActiveRecord collections based on arguments for pagination, filtering and sorting
- `AbstractFilter` - Base class for custom filters
- `FilterFactory` - Create filters dynamically based on query method arguments
- `SortHash` - Handle sorting parameters
- Base class filter implementations for boolean, enum, numeric, and range filters

### Pagination

Enable paginated access to resources across the API:

- `Paginator` - Standard pagination implementation
- `PaginatorBuilder` - Build paginators with custom configurations
- `SnapshotPaginator` - Enable record iteration (one by one) across results in a page, even when the underlying records change state (and may no longer be at the same position in the result set)

### Types

Type definitions and validation using dry-types:

- `BaseType` - Base type for value objects
- `CollectionResultMetadata` - Metadata for paginated collections
- `Result` - Generic result type to be returned from your API methods
- `AggregateType` - Composite types made of attributes from other types
- Filter definition types for various data types

### Batch Operations

Utilities for processing large datasets efficiently:

- `ValuesInBatches` - Process values in batches
- `ValuesInBackgroundBatches` - Process values in background batches

## Usage

### Basic Example

See the test files for more detailed examples, but here's a simple usage example. 

Let's assume your system has Author, Comment and BlogPost ActiveRecord models.

1. Define value objects to contain the data passed out of the API:

```ruby

# public/author_type.rb
class AuthorType < PackAPI::Types::BaseType
  attribute :id, ::Types::String
  attribute :name, ::Types::String
end

# public/comment_type.rb
class CommentType < PackAPI::Types::BaseType
  attribute :text, ::Types::String
end

# public/blog_post_type.rb
class BlogPostType < PackAPI::Types::BaseType
  attribute :id, ::Types::String
  attribute :legacy_id, ::Types::String
  attribute :title, ::Types::String
  attribute :persisted, ::Types::Bool
  attribute :contents, ::Types::String.optional
  optional_attribute :associated, AuthorType
  optional_attribute :notes, ::Types::Array.of(CommentType)
  optional_attribute :earnings_float, ::Types::Coercible::Float
end
```

2. Define the rules for mapping between the domain models and the API value objects:

```ruby
# api/author_attribute_map.rb
class AuthorAttributeMap < PackAPI::Mapping::AttributeMap
  api_type AuthorType
  model_type Author
  map :id, to: :external_id
  # name and blog_posts share their names with the model attributes, so they need no map
end

# api/comment_attribute_map.rb
class CommentAttributeMap < PackAPI::Mapping::AttributeMap
  api_type CommentType
  model_type Comment
  map :text, to: :txt
end

# api/blog_post_attribute_map.rb
class BlogPostAttributeMap < PackAPI::Mapping::AttributeMap
  api_type BlogPostType
  model_type BlogPost

  # API attributes with the same name as the model attribute (title, legacy_id) need no map

  map :contents, from_model_attribute: ->(attachment) { attachment&.blob }

  # example API attribute mapped to a model attribute of a different name
  map :id, to: :external_id

  # example of API attribute mapped to a model method (unidirectional)
  map :persisted, to: :persisted?, readonly: true

  # example of API association mapped to a model association
  # (the association_id can also be passed in, and reported on during error cases)
  map :associated, to: :author,
      from_api_attribute: ->(author_id) { Author.find_by(external_id: author_id) }

  map :notes, to: :comments, transform_nested_attributes_with: CommentAttributeMap

  # example of OPTIONAL API attribute (association) mapped to a model method (bidirectional)
  map :earnings_float, to: :earnings_float
end

```

3. Implement filters and register them in a filter factory. Attributes marked `filterable: true` on the value object
   type get an `AttributeFilter` each via `register_attribute_filters`; anything else is a filter class of its own:

```ruby
# models/filters/blog_post/filter_factory.rb
module Filters::BlogPost
  class FilterFactory < PackAPI::Querying::FilterFactory
    def initialize
      super
      register_attribute_filters(BlogPostAttributeMap)
      register_filter(AuthorFilter) # keyed by AuthorFilter.filter_name
    end
  end
end

# api/blog_post_filter_map.rb
# resolves Filters::BlogPost::FilterFactory and BlogPostAttributeMap from its own name
class BlogPostFilterMap < PackAPI::Mapping::FilterMap; end
```

The registry and value object factory follow the same pattern, so they are usually empty classes too
(see [Naming Conventions](#naming-conventions)):

```ruby
# api/attribute_map_registry.rb
class AttributeMapRegistry < PackAPI::Mapping::AttributeMapRegistry; end

# api/value_object_factory.rb
class ValueObjectFactory < PackAPI::Mapping::ValueObjectFactory; end
```

4. Implement a query endpoint using the attribute map:

```ruby
def query_blog_posts(cursor = nil, search = nil, sort = nil, page_size = 50, filters = {}, optional_attributes = [])
  collection = BlogPost.all
  
  # avoid N+1 queries for optional attributes that are associations
  if optional_attributes.include?(:associated)
    collection = collection.includes(:author)
  end
  
  # convert the search terms to something used by the CollectionQuery to perform searches (hash of model attributes to search terms)
  if search.present?
    # search through blog post title and comments
    collection = collection.includes(:comments)
    model_search = {
      'title' => search,
      "#{Comment.table_name}.txt" => search,
    }
  end
  
  # convert the API sort to model sort
  model_sort = BlogPostAttributeMap.model_attribute_keys(PackAPI::Querying::SortHash.new(sort))

  # convert the API filters to model filters
  model_filters = BlogPostFilterMap.new.from_api_filters(filters)

  # build and execute the query
  query = PackAPI::Querying::CollectionQuery.new(collection:)
  query.filter_factory = Filters::BlogPost::FilterFactory.new
  query.call(cursor:, per_page: page_size, sort: model_sort, search: model_search, filters: model_filters)
  
  # build and return the result
  PackAPI::Types::Result.from_collection(models: query.results,
                                         value_object_factory: ValueObjectFactory.new,
                                         optional_attributes:,
                                         sort: BlogPostAttributeMap.api_attribute_keys(query.sort),
                                         paginator: query.paginator)
end
```

## Naming Conventions

PackAPI infers collaborators from class names so that the classes a pack needs are mostly declarations of intent
with empty bodies. Every convention is a **default**, not a requirement: pass the argument or make the registration
explicitly and the convention is never consulted. A project that names things differently keeps working unchanged.

Given a pack namespace `Blogging` and a resource `Post`:

| Class | Infers | Explicit alternative |
|---|---|---|
| `Blogging::PostFilterMap < Mapping::FilterMap` | `filter_factory` = `Blogging::Filters::Post::FilterFactory.new`<br>`attribute_map_class` = `Blogging::PostAttributeMap` (nil when absent) | `super(filter_factory: ..., attribute_map_class: ...)` in `initialize` |
| `Blogging::AttributeMapRegistry < Mapping::AttributeMapRegistry` | attribute map for model `Blogging::Post` = `Blogging::PostAttributeMap`<br>nested models resolve to nested maps: `Blogging::Post::Draft` -> `Blogging::PostAttributeMap::Draft` | `register_attribute_map(SomeAttributeMap)`; an explicit registration always wins over the convention |
| `Blogging::ValueObjectFactory < Mapping::ValueObjectFactory` | `attribute_map_registry` = `Blogging::AttributeMapRegistry` | `set_attribute_map_registry(SomeRegistry)` |
| any `Mapping::AttributeMap` with an `api_type` | an identity mapping (`map :title`) for every attribute of the api type | `map :title, to: :headline` (or any other `map` option) overrides the identity mapping for that attribute |
| `Querying::FilterFactory#register_filter(klass)` | filter name = `klass.filter_name` | `register_filter(klass, name: :other)` or `register_filter(name:, klass:)` |
| `Querying::FilterFactory#register_attribute_filters(attribute_map_class)` | one `AttributeFilter` per attribute marked `filterable: true` on the api type | register attribute filters by hand |

Notes:

- The identity mapping has no opt-out because it never changes behaviour: an api attribute without a mapping was
  already rejected as an `unknown attribute` on both read and write, so any working attribute map mapped every api
  attribute explicitly. The default only fills those mandatory entries.
- Explicitly declared `map` entries keep their declared position ahead of the identity defaults. Nested attribute
  error keys are converted with a reverse lookup that takes the first mapping pointing at a model attribute, so
  declaration order is significant when several api attributes map to the same model attribute.
- Conventions resolve constants lazily, on first use, so autoloading (Zeitwerk) works without eager registration.
- A namespace is the class name minus its last segment (`Blogging::PostFilterMap` -> `Blogging`). Top-level classes
  resolve top-level collaborators (`PostFilterMap` -> `Filters::Post::FilterFactory`).

## Testing with Shared Examples

PackAPI includes RSpec shared examples to help test your API query methods. These are opt-in and only need to be loaded if you're using RSpec.

### Loading Shared Examples

In your `spec_helper.rb` or `rails_helper.rb`, require the shared examples you need:

```ruby
# Load all shared examples
require 'pack_api/rspec/shared_examples_for_api_query_methods'
require 'pack_api/rspec/shared_examples_for_paginated_results'

# Or load them individually as needed
require 'pack_api/rspec/shared_examples_for_api_query_methods'
```

### Using the Shared Examples

**Testing API Query Methods:**

```ruby
RSpec.describe 'query_blog_posts' do
  let(:api_query_method) { method(:query_blog_posts) }
  let(:resources) { BlogPost.all }

  it_behaves_like 'an API query method'

  # With custom options
  it_behaves_like 'an API query method',
    model_id_attribute: :uuid,
    supports_search: true do
    let(:search_terms) { "searchable text" }
    let(:matched_resources) { BlogPost.where("title LIKE ?", "%searchable%") }
  end
end
```

**Testing Paginated Methods:**

```ruby
RSpec.describe 'paginated query' do
  let(:paginated_api_query_method) { method(:query_blog_posts) }
  let(:paginated_resources) { BlogPost.all }

  it_behaves_like 'a paginated API method', model_id_attribute: :external_id
end
```

## Development

After checking out the repo, run:

```bash
bundle install
```

Run the test suite:

```bash
bundle exec rspec
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/flytedesk/pack_api.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
