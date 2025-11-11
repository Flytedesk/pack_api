# frozen_string_literal: true

module PackAPI::Querying
  class ComposableQuery
    def initialize(initial_query)
      @query = initial_query
    end

    def add(query_clause)
      @query = @query.merge(query_clause)
      self
    end

    def build
      @query
    end

    def to_sql
      @query.to_sql
    end
  end
end