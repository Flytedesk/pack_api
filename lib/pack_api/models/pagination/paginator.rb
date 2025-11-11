# frozen_string_literal: true

##
# Enable paged access to large record sets.
#
# For any given query and sort, limit the returned item count, and provide access to adjacent subsets of the records.
# An opaque token (aka "cursor") is created and passed to the caller for the following "pages" of data:
#   - next page
#   - previous page
#   - first page
#   - last page
#
# A cursor acts like a bookmark to a record in a recordset.
#
# The pagination strategy used is the most basic one: Limit-Offset.
# More sophisticated ones exist (https://www.citusdata.com/blog/2016/03/30/five-ways-to-paginate/)
# and can be implemented as needed.
#
# Construct an object of this type using the {PaginatorBuilder}
# The various *_cursor methods return opaque tokens representing {Paginator} objects
# They should be parsed using the {PaginatorCursor} class.
#
module PackAPI::Pagination
  class Paginator
    ###
    # @param [Hash] query The query parameters used to define the recordset.
    # @param [String|Symbol|Hash|Arel] sort The ordering used to define the recordset
    # @param [Integer|:all] per_page The count of items to include on each result page, or :all for single page results
    # @param [Integer] offset The starting index of the next result page
    # @param [Integer] total_items The count of items in the result set
    # @param [Any|nil] metadata optional, extra data structure to be passed along with the cursor
    attr_accessor :query, :sort, :total_items, :per_page, :offset, :metadata

    DEFAULT_PER_PAGE = 20
    DEFAULT_SORT = 'id asc'

    ###
    # The range of items included in the results.
    def item_range
      return 0..0 if per_page != :all && per_page.zero?

      lower_bound = offset + 1
      upper_bound = per_page == :all ?
                      total_items :
                      [(offset + per_page), total_items].min
      lower_bound..upper_bound
    end

    ###
    # Represent the record set as a cursor-- this captures the current search criteria (filters, sort, etc.)
    def recordset_cursor
      make_cursor(recordset_cursor_params)
    end

    ###
    # Represents a single page of results in the current record set-- the "current" page
    def current_page_cursor
      make_cursor(current_page_cursor_params)
    end

    ###
    # Represents a single page of results in the current record set-- the "next" N results
    def next_page_cursor
      make_cursor(next_page_params)
    end

    ###
    # Represents a single page of results in the current record set-- the "previous" N results
    def previous_page_cursor
      make_cursor(previous_page_params)
    end

    ###
    # Represents a single page of results in the current record set-- the "first" N results
    def first_page_cursor
      make_cursor(first_page_params)
    end

    ###
    # Represents a single page of results in the current record set-- the "last" N results
    def last_page_cursor
      make_cursor(last_page_params)
    end

    def limit
      return nil if per_page == :all

      per_page
    end

    private

    def more_pages?
      return false if per_page == :all || per_page.zero?

      offset + per_page < total_items
    end

    def recordset_cursor_params
      cursor_params.deep_merge(offset: 0, per_page: :all, metadata: { kind: :recordset })
    end

    def current_page_cursor_params
      return nil if per_page != :all && per_page.zero?

      cursor_params.deep_merge(offset: offset, metadata: { kind: :current_page })
    end

    def next_page_params
      return nil unless more_pages?

      cursor_params.deep_merge(offset: offset + per_page, metadata: { kind: :next_page })
    end

    def previous_page_params
      return nil if offset.zero?

      cursor_params.deep_merge(offset: offset - per_page, metadata: { kind: :previous_page })
    end

    def first_page_params
      return nil if offset.zero?

      cursor_params.deep_merge(offset: 0, metadata: { kind: :first_page })
    end

    def last_page_params
      return nil unless more_pages?

      last_page_offset = (last_item_offset / per_page).floor * per_page
      cursor_params.deep_merge(offset: last_page_offset, metadata: { kind: :last_page })
    end

    def last_item_offset
      total_items - 1
    end

    def make_cursor(params)
      return nil if params.nil?

      PaginatorCursor.create(**params)
    end

    def cursor_params
      {
        offset:,
        sort:,
        total_items:,
        per_page:,
        query:,
        metadata:
      }
    end
  end
end
