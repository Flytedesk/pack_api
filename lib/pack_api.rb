# frozen_string_literal: true
require "zeitwerk"
require "active_model"
require "active_record"
require "dry-types"
require "dry/struct"
require "brotli"

require_relative "types"
require_relative "pack_api/version"

module PackAPI
  autoload :InternalError, "pack_api/internal_error"
  autoload :ValuesInBatches, "pack_api/values_in_batches"
  autoload :ValuesInBackgroundBatches, "pack_api/values_in_background_batches"

  module Mapping
    autoload :AbstractTransformer, "pack_api/mapping/abstract_transformer"
    autoload :AttributeHashTransformer, "pack_api/mapping/attribute_hash_transformer"
    autoload :NullTransformer, "pack_api/mapping/null_transformer"
    autoload :APIToModelAttributesTransformer, "pack_api/mapping/api_to_model_attributes_transformer"
    autoload :ModelToAPIAttributesTransformer, "pack_api/mapping/model_to_api_attributes_transformer"
    autoload :ErrorHashToAPIAttributesTransformer, "pack_api/mapping/error_hash_to_api_attributes_transformer"
    autoload :NormalizedAPIAttribute, "pack_api/mapping/normalized_api_attribute"
    autoload :AttributeMap, "pack_api/mapping/attribute_map"
    autoload :AttributeMapRegistry, "pack_api/mapping/attribute_map_registry"
    autoload :FilterMap, "pack_api/mapping/filter_map"
    autoload :ValueObjectFactory, "pack_api/mapping/value_object_factory"
  end

  module Pagination
    autoload :OpaqueTokenV2, "pack_api/pagination/opaque_token_v2"
    autoload :PaginatorCursor, "pack_api/pagination/paginator_cursor"
    autoload :Paginator, "pack_api/pagination/paginator"
    autoload :PaginatorBuilder, "pack_api/pagination/paginator_builder"
    autoload :SnapshotPaginator, "pack_api/pagination/snapshot_paginator"
  end

  module Querying
    autoload :AbstractFilter, "pack_api/querying/abstract_filter"
    autoload :AbstractBooleanFilter, "pack_api/querying/abstract_boolean_filter"
    autoload :AbstractEnumFilter, "pack_api/querying/abstract_enum_filter"
    autoload :AbstractNumericFilter, "pack_api/querying/abstract_numeric_filter"
    autoload :AbstractRangeFilter, "pack_api/querying/abstract_range_filter"
    autoload :DefaultFilter, "pack_api/querying/default_filter"
    autoload :DiscoverableFilter, "pack_api/querying/discoverable_filter"
    autoload :DynamicEnumFilter, "pack_api/querying/dynamic_enum_filter"
    autoload :AttributeFilter, "pack_api/querying/attribute_filter"
    autoload :AttributeFilterFactory, "pack_api/querying/attribute_filter_factory"
    autoload :FilterFactory, "pack_api/querying/filter_factory"
    autoload :ComposableQuery, "pack_api/querying/composable_query"
    autoload :CollectionQuery, "pack_api/querying/collection_query"
    autoload :SortHash, "pack_api/querying/sort_hash"
  end

  module Types
    autoload :BaseType, "pack_api/types/base_type"
    autoload :AggregateType, "pack_api/types/aggregate_type"
    autoload :GloballyIdentifiable, "pack_api/types/globally_identifiable"
    autoload :Result, "pack_api/types/result"
    autoload :CollectionResultMetadata, "pack_api/types/collection_result_metadata"
    autoload :FilterOption, "pack_api/types/filter_option"
    autoload :SimpleFilterDefinition, "pack_api/types/simple_filter_definition"
    autoload :BooleanFilterDefinition, "pack_api/types/boolean_filter_definition"
    autoload :EnumFilterDefinition, "pack_api/types/enum_filter_definition"
    autoload :NumericFilterDefinition, "pack_api/types/numeric_filter_definition"
    autoload :RangeFilterDefinition, "pack_api/types/range_filter_definition"
    autoload :CustomFilterDefinition, "pack_api/types/custom_filter_definition"
  end
end