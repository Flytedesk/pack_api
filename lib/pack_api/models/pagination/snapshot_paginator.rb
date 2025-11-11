# frozen_string_literal: true

module PackAPI::Pagination

  ###
  # Current Page Snapshot Query is a query that targets the records in a given page of
  # a record set (regardless of how those records may change state). Whereas the contents of
  # the nth page in a record set may change, the cached results query for that same page will not.
  #
  # This class represents the paginator for such a query.
  class SnapshotPaginator
    METADATA_KEY = :snapshot

    attr_accessor :paginator, :results, :cursor

    ###
    # Create a snapshot from the current page results of a record set.
    def self.cursor_for_results(results, table_name:, collection_key:)
      offsets = {}
      case_statement = results.map.with_index do |record, index|
        record_id = record.send(collection_key)
        offsets[record_id.to_s] = index.to_s
        # Use SQL standard CAST to convert both sides to strings for comparison
        "WHEN CAST(\"#{table_name}\".\"#{collection_key}\" AS VARCHAR) = '#{record_id}' THEN #{index}"
      end
      sort_sql = "CASE #{case_statement.join("\n")} END"
      filters = { collection_key => results.pluck(collection_key) }
      paginator = PaginatorBuilder.build do |builder|
        builder.set_params(query: { filters: },
                           metadata: { METADATA_KEY => true, offsets:, collection_key: },
                           sort: Arel.sql(sort_sql),
                           total_items: results.size,
                           per_page: results.size)
      end
      paginator.current_page_cursor
    end

    def initialize(paginator)
      raise PackAPI::InternalError, 'Paginator does not represent CachedResultsQuery' if paginator.metadata.nil?

      @paginator = paginator
    end

    ###
    # Update the query to focus the result onto the given record within the snapshot.
    # If no record_id is provided, it will attempt to guess the record_id based on the current paginator state.
    # NOTE This method assumes that the paginator.total_items has already been updated to reflect the query's count.
    def apply_to(query, record_id: nil)
      if has_valid_offsets?
        # if no record_id is provided, no customization is needed
        return query unless record_id.present?

        self.target_record_id = record_id
        updated_query = query.offset(paginator.offset).limit(paginator.limit)
        @results = updated_query.to_a
        @cursor = paginator.current_page_cursor
        updated_query
      else
        # unless we have either a record_id or an offset, there is no customization needed
        return query unless paginator.offset.present? || record_id.present?

        # Step 1: If we don't have a record_id, try to guess what record_id the user was trying to access
        record_id ||= target_record_id

        # Step 2: Fetch all the records in the snapshot -- remove the offset and limits on the current query
        snapshot_results = query.unscope(:offset, :limit).to_a

        # Step 3: Update the offsets based on the current query results
        update_offsets(snapshot_results)

        # Step 4: get the correct offset for the given record_id
        self.target_record_id = record_id

        # Step 5: Filter the results to just the record_id
        collection_key = paginator.metadata[:collection_key]
        @results = snapshot_results.select { it.send(collection_key).to_s == record_id.to_s }
        @cursor = paginator.current_page_cursor
        query.offset(paginator.offset).limit(paginator.limit)
      end
    end

    ###
    # Is the paginator one produced by this class?
    def self.generated?(paginator)
      paginator.metadata&.fetch(METADATA_KEY, nil).presence
    end

    private

    def has_valid_offsets?
      paginator.metadata[:offsets].size == paginator.total_items
    end

    ###
    # Update the paginator's state based on the current results of the query.
    def update_offsets(results)
      paginator.metadata.merge!(offsets: results_offsets(results))
    end

    def target_record_id
      return unless paginator.offset

      paginator.metadata[:offsets].key(paginator.offset.to_s).to_s
    end

    def target_record_id=(record_id)
      paginator.offset = lookup_offset(record_id)
      paginator.per_page = 1
    end

    def results_offsets(results)
      collection_key = paginator.metadata[:collection_key]
      results.map.with_index do |record, index|
        record_id = record.send(collection_key)
        [record_id.to_s, index.to_s]
      end.to_h
    end

    ###
    # @return [Integer] The offset to use with the CachedResultsQuery to select the given record
    def lookup_offset(record_id)
      metadata = paginator.metadata[:offsets]
      return 0 unless metadata

      stringified_record_id = record_id.to_s
      # metadata can have symbol keys or string keys, depending on how the cursor was created.
      offset =  metadata.include?(stringified_record_id) ?
                  metadata[stringified_record_id] :
                  metadata[stringified_record_id.to_sym]
      offset.to_i
    end
  end
end