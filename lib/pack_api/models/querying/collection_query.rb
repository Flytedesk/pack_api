# frozen_string_literal: true

module PackAPI::Querying
  ###
  # This is a generic query that can be used to query any collection of ActiveRecord models and then
  # expose the results as a collection of value objects.
  #
  # It allows paginated queries, as well as record iteration
  # queries (using snapshot cursors). In order to enable record iteration mode, the query must be called with
  # both a snapshot cursor and a primary key filter.
  class CollectionQuery
    attr_accessor :collection, :collection_key, :filter_factory, :default_sort, :paginator, :sort, :results

    ###
    # Create the query object.
    #
    # @ param [ActiveRecord::Relation] collection The collection to query
    # @ param [Object] value_object_factory The factory to use to convert model objects to value objects
    # @ param [String|Symbol|Hash|Arel] default_sort The default sort to use if none is specified in the query
    # @ param [String|Symbol] collection_key Unique and indexed key to use for the collection.
    #  Used for tie-breaker sort criteria and drives the record id lookup when in record iteration mode.
    def initialize(collection:, collection_key: nil, default_sort: nil)
      @collection = collection
      @collection_key = (collection_key || collection.primary_key).to_sym
      @default_sort = default_sort
      @filter_factory = FilterFactory.new
      @filter_factory.use_default_filter = true
    end

    ###
    # Perform the query.
    #
    # @param [String] cursor A pagination cursor referencing a page of records in a recordset
    # @param [Integer|Symbol] per_page A count of how many items to include on each page, or :all to skip pagination
    # @param [String|Symbol|Hash|Arel] sort ActiveRecord `order` arguments.
    # @param [Hash] search Attribute/value pairs that define the bounds of the recordset using wildcard matching (attribute LIKE %value%)
    # @param [Hash] filters the keys are names of filters, the values are arguments to the filters
    def call(cursor: nil, per_page: nil, sort: nil, search: nil, filters: {})
      record_id = filters.delete(collection_key) if cursor.present? && filters[collection_key].present?
      build_paginator(cursor, filters, per_page, search, sort)
      build_active_record_query(record_id)
    end

    def to_sql
      @query.to_sql
    end

    def reset
      @results = nil
      @query = nil
      @paginator = nil
      @sort = nil
      @current_page_snapshot_cursor = nil
    end

    def current_page_snapshot_cursor
      @current_page_snapshot_cursor ||= PackAPI::Pagination::SnapshotPaginator.cursor_for_results(results,
                                                                                                  table_name: collection.klass.table_name,
                                                                                                  collection_key:)
    end

    private

    def build_active_record_query(record_id)
      @query = collection
      if paginator.query&.fetch(:search, nil).present?
        apply_search(search: paginator.query[:search])
      end
      if paginator.query&.fetch(:filters, nil).present?
        apply_filters(filters: paginator.query[:filters])
      end

      @sort = paginator.sort
      paginator.total_items = @query.count
      @query = @query.order(paginator.sort)
                     .offset(paginator.offset)
                     .limit(paginator.limit)

      if PackAPI::Pagination::SnapshotPaginator.generated?(paginator)
        snapshot_paginator = PackAPI::Pagination::SnapshotPaginator.new(paginator)
        @query = snapshot_paginator.apply_to(@query, record_id:)
        @results = snapshot_paginator.results
        @current_page_snapshot_cursor = snapshot_paginator.cursor
      end

      @results ||= @query.to_a
    end

    def build_paginator(cursor, filters, per_page, search, sort)
      @paginator = PackAPI::Pagination::PaginatorBuilder.build do |builder|
        cursor.present? ?
          builder.set_cursor(cursor:) :
          builder.set_params(sort: stable_sort(default_sort)) # set a default sort for a new query

        builder.set_params(sort: stable_sort(sort.presence)) if sort.present?
        builder.set_params(query: { filters: }) if filters.present?
        builder.set_params(query: { search: }) if search.present?
        builder.set_params(per_page:) if per_page.present?
      end
    end

    def apply_search(search:)
      search.keys.each_with_index do |column, index|
        value = search[column]
        @query = index.positive? ?
                   @query.or(collection.where("LOWER(#{column}) LIKE LOWER(?)", "%#{value}%")) :
                   @query.where("LOWER(#{column}) LIKE LOWER(?)", "%#{value}%")
      end
    end

    def apply_filters(filters:)
      filtered_query = ComposableQuery.new(@query)
      filter_factory.create_filters(filters).each { |filter| filter.apply_to(filtered_query) }
      @query = filtered_query.build
    end

    def stable_sort(sort)
      return sort if sort.is_a?(Arel::Nodes::SqlLiteral)

      SortHash.new(sort).tap do |sort_hash|
        sort_hash[collection_key] = :asc unless sort_hash.key?(collection_key)
      end
    end
  end
end
