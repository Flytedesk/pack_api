# PackAPI

Building blocks for implementing APIs around domain models.

## Overview

PackAPI provides a comprehensive set of tools for building robust API layers on top of domain models. It includes utilities for:

- **Data transformation** - Elements for passing data out of the API
- **Filter definitions** - Elements for describing the filters supported by query endpoints in the API
- **Attribute mapping** - Elements for building the mapping between domain models and API models
- **Query building** - Elements for building query endpoints based on user inputs (sort, filter, pagination)
- **Batch operations** - Elements for retrieving multiple pages of data from other query endpoints

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
- `AttributeMapRegistry` - Centralized registry for attribute mappings
- `ModelToAPIAttributesTransformer` - Transform model attributes to API format
- `APIToModelAttributesTransformer` - Transform API attributes to model format
- `ValueObjectFactory` - Create value objects from raw data

### Querying

Build flexible query interfaces with support for filtering, sorting, and pagination:

- `ComposableQuery` - Build complex queries from simpler components
- `CollectionQuery` - Query collections with filtering and sorting
- `AbstractFilter` - Base class for custom filters
- Filter implementations for boolean, enum, numeric, and range filters
- `FilterFactory` - Create filters dynamically based on query method arguments
- `SortHash` - Handle sorting parameters

### Pagination

Enable paginated access to resources across the API:

- `Paginator` - Standard pagination implementation
- `PaginatorBuilder` - Build paginators with custom configurations
- `SnapshotPaginator` - Enable record iteration (one by one) across results in a page, 
even when the underlying records change state (and may no longer be at the same position in the result set)

### Types

Type definitions and validation using dry-types:

- `BaseType` - Base type for API models
- `CollectionResultMetadata` - Metadata for paginated collections
- `Result` - Generic result type
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
  map :name, to: :name
  map :id, to: :external_id
  map :blog_posts
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

  # example API attribute mapped to a model attribute of the same name
  map :title

  map :contents, from_model_attribute: ->(attachment) { attachment&.blob }

  # example API attribute mapped to a model attribute of a different name
  map :id, to: :external_id

  # example of API attribute ending in "_id"
  map :legacy_id

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

3. Implement a query endpoint using the attribute map:

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
