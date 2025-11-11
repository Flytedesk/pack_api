# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-11-10

### Added

- Initial release of PackAPI gem
- Mapping module for transforming data between domain models and API representations
  - AttributeMap for defining bidirectional mappings
  - AttributeMapRegistry for centralized mapping management
  - ModelToAPIAttributesTransformer and APIToModelAttributesTransformer
  - ValueObjectFactory for creating value objects
- Querying module for building flexible query interfaces
  - ComposableQuery and CollectionQuery
  - Filter implementations (boolean, enum, numeric, range)
  - FilterFactory for dynamic filter creation
  - SortHash for handling sorting parameters
- Pagination module with multiple strategies
  - Paginator for standard pagination
  - SnapshotPaginator for consistent results
  - PaginatorBuilder for custom configurations
  - OpaqueTokenV2 for secure cursor tokens
- Types module with dry-types integration
  - BaseType and AggregateType
  - Result and CollectionResultMetadata
  - Filter definition types
- Batch operation utilities
  - ValuesInBatches for synchronous batch processing
  - ValuesInBackgroundBatches for asynchronous batch processing

[Unreleased]: https://github.com/flytedesk/pack_api/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/flytedesk/pack_api/releases/tag/v0.1.0
