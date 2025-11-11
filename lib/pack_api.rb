# frozen_string_literal: true

require "active_model"
require "active_record"
require "dry-types"
require "dry/struct"
require "brotli"

require_relative "types"
require_relative "pack_api/version"
require_relative "pack_api/config/dry_types_initializer"

# Load in dependency order
module PackAPI
  autoload :InternalError, "pack_api/models/internal_error"
  autoload :ValuesInBatches, "pack_api/models/values_in_batches"
  autoload :ValuesInBackgroundBatches, "pack_api/models/values_in_background_batches"

  module Mapping
    autoload :AbstractTransformer, "pack_api/models/mapping/abstract_transformer"
    autoload :AttributeHashTransformer, "pack_api/models/mapping/attribute_hash_transformer"
    autoload :NullTransformer, "pack_api/models/mapping/null_transformer"
    autoload :APIToModelAttributesTransformer, "pack_api/models/mapping/api_to_model_attributes_transformer"
    autoload :ModelToAPIAttributesTransformer, "pack_api/models/mapping/model_to_api_attributes_transformer"
    autoload :ErrorHashToAPIAttributesTransformer, "pack_api/models/mapping/error_hash_to_api_attributes_transformer"
    autoload :NormalizedAPIAttribute, "pack_api/models/mapping/normalized_api_attribute"
    autoload :AttributeMap, "pack_api/models/mapping/attribute_map"
    autoload :AttributeMapRegistry, "pack_api/models/mapping/attribute_map_registry"
    autoload :FilterMap, "pack_api/models/mapping/filter_map"
    autoload :ValueObjectFactory, "pack_api/models/mapping/value_object_factory"
  end

  module Pagination
    autoload :OpaqueTokenV2, "pack_api/models/pagination/opaque_token_v2"
    autoload :PaginatorCursor, "pack_api/models/pagination/paginator_cursor"
    autoload :Paginator, "pack_api/models/pagination/paginator"
    autoload :PaginatorBuilder, "pack_api/models/pagination/paginator_builder"
    autoload :SnapshotPaginator, "pack_api/models/pagination/snapshot_paginator"
  end

  module Querying
    autoload :AbstractFilter, "pack_api/models/querying/abstract_filter"
    autoload :AbstractBooleanFilter, "pack_api/models/querying/abstract_boolean_filter"
    autoload :AbstractEnumFilter, "pack_api/models/querying/abstract_enum_filter"
    autoload :AbstractNumericFilter, "pack_api/models/querying/abstract_numeric_filter"
    autoload :AbstractRangeFilter, "pack_api/models/querying/abstract_range_filter"
    autoload :DefaultFilter, "pack_api/models/querying/default_filter"
    autoload :DiscoverableFilter, "pack_api/models/querying/discoverable_filter"
    autoload :DynamicEnumFilter, "pack_api/models/querying/dynamic_enum_filter"
    autoload :AttributeFilter, "pack_api/models/querying/attribute_filter"
    autoload :AttributeFilterFactory, "pack_api/models/querying/attribute_filter_factory"
    autoload :FilterFactory, "pack_api/models/querying/filter_factory"
    autoload :ComposableQuery, "pack_api/models/querying/composable_query"
    autoload :CollectionQuery, "pack_api/models/querying/collection_query"
    autoload :SortHash, "pack_api/models/querying/sort_hash"
  end

  module Types
    autoload :BaseType, "pack_api/models/types/base_type"
    autoload :AggregateType, "pack_api/models/types/aggregate_type"
    autoload :GloballyIdentifiable, "pack_api/models/types/globally_identifiable"
    autoload :Result, "pack_api/models/types/result"
    autoload :CollectionResultMetadata, "pack_api/models/types/collection_result_metadata"
    autoload :FilterOption, "pack_api/models/types/filter_option"
    autoload :SimpleFilterDefinition, "pack_api/models/types/simple_filter_definition"
    autoload :BooleanFilterDefinition, "pack_api/models/types/boolean_filter_definition"
    autoload :EnumFilterDefinition, "pack_api/models/types/enum_filter_definition"
    autoload :NumericFilterDefinition, "pack_api/models/types/numeric_filter_definition"
    autoload :RangeFilterDefinition, "pack_api/models/types/range_filter_definition"
    autoload :CustomFilterDefinition, "pack_api/models/types/custom_filter_definition"
  end
end
