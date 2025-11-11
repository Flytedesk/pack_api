# frozen_string_literal: true

module PackAPI::Types
  class CollectionResultMetadata < Dry::Struct
    attribute :first_item, Types::Integer
    attribute :last_item, Types::Integer
    attribute :total_items, Types::Integer

    ###
    # Cursors for the current record set (see PackAPI::Paginator)
    attribute? :next_page_cursor, Types::String.optional
    attribute? :previous_page_cursor, Types::String.optional
    attribute? :first_page_cursor, Types::String.optional
    attribute? :last_page_cursor, Types::String.optional
    attribute? :current_page_cursor, Types::String.optional
    attribute? :recordset_cursor, Types::String.optional

    ###
    # A cursor representing a separate query that will always yield what the current_page_cursor produces
    attribute? :current_page_snapshot_cursor, Types::String.optional

    attribute? :sort, Types::Any.optional

    def self.default
      new(
        first_item: 1,
        last_item: 1,
        total_items: 1
      )
    end

    def self.from_paginator(paginator, sort = nil, current_page_snapshot_cursor = nil)
      new(
        first_item: paginator.item_range.begin,
        last_item: paginator.item_range.end,
        total_items: paginator.total_items,
        next_page_cursor: paginator.next_page_cursor,
        previous_page_cursor: paginator.previous_page_cursor,
        current_page_cursor: paginator.current_page_cursor,
        first_page_cursor: paginator.first_page_cursor,
        last_page_cursor: paginator.last_page_cursor,
        recordset_cursor: paginator.recordset_cursor,
        sort: sort || paginator.sort,
        current_page_snapshot_cursor:
      )
    end
  end
end