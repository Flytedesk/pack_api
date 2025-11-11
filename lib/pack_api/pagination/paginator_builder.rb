# frozen_string_literal: true

# Make it easier to correctly instantiate a Paginator object, given that a few different
# use cases exist each having different data (arguments).
#
# This is an application of the Builder pattern (see https://refactoring.guru/design-patterns/builder) for Ruby.
#
# Two scenarios exist for constructing a Paginator object:
#
# 1. Starting a new query.
#   Uses the following parameters:
#   * query - filters used to define the recordset
#   * sort - ordering used to define the recordset
#   * per_page - count of items to include on each result page
#   * offset - starting index of the next result page
#   * total_items - count of items in the result set, if known
#
# OR
#
# 2. Continuing an existing query
#   Uses the following parameters:
#   * a pagination cursor
#   * sort (optional) - Used to override the sort order of the cursor; effectively creates a new query
#   * per_page (optional) - Used to override the per_page of the cursor; will limit the count of results in the
#
module PackAPI::Pagination
  class PaginatorBuilder
    attr_accessor :paginator

    def self.build
      builder = new
      yield(builder)
      builder.paginator
    end

    def initialize
      @paginator = Paginator.new
    end

    def set_cursor(cursor:, per_page: nil, sort: nil)
      cursor_params = PaginatorCursor.parse(cursor)
      effective_per_page = per_page.presence || cursor_params[:per_page]
      effective_per_page = :all if effective_per_page.to_s == 'all'

      @paginator.query = cursor_params[:query]
      @paginator.total_items = cursor_params[:total_items]
      @paginator.per_page = effective_per_page
      @paginator.sort = sort.presence || cursor_params[:sort]
      @paginator.offset = effective_offset(cursor_params, sort)
      @paginator.metadata = cursor_params[:metadata]
    end

    ###
    # @param [Proc<Hash>|Hash] query The query parameters used to define the recordset.
    # @param [String|Symbol|Hash|Arel] sort The ordering used to define the recordset
    # @param [Integer|:all] per_page The count of items to include on each result page, or :all for single page results
    # @param [Integer|nil] offset The starting index of the next result page
    # @param [Integer|nil] total_items The count of items in the result set, if known.
    # @param [Any|nil] metadata Any extra data structure to be passed along with the cursor
    def set_params(query: nil, sort: nil, total_items: nil, per_page: nil, offset: nil, metadata: nil)
      @paginator.query ||= {}
      if query.present?
        original_query = @paginator.query
        @paginator.query = @paginator.query.deep_merge(resolve_query_params(query).deep_symbolize_keys)
        @recordset_changed = original_query.to_json != @paginator.query.to_json
      end

      @paginator.sort ||= Paginator::DEFAULT_SORT
      if sort.present?
        @recordset_changed = sort.to_json != @paginator.sort.to_json
        @paginator.sort = sort.presence
      end

      @paginator.total_items ||= 0
      if total_items.present?
        @paginator.total_items = total_items
      end

      @paginator.offset ||= 0
      if offset.present?
        @paginator.offset = offset
      elsif @recordset_changed
        @paginator.offset = 0
      end

      @paginator.per_page ||= Paginator::DEFAULT_PER_PAGE
      if per_page.present?
        @paginator.per_page = per_page
        @paginator.offset = 0 if per_page == :all
      end

      @paginator.metadata ||= metadata
    end

    private

    def effective_offset(cursor_params, sort)
      sort_changed = sort.to_json != cursor_params[:sort].to_json
      sort_override = sort.present? && sort_changed
      sort_override ?
        0 :
        cursor_params[:offset]
    end

    def resolve_query_params(query)
      query.is_a?(Proc) ?
        query.call :
        query
    end

  end
end