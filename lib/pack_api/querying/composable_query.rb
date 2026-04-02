# frozen_string_literal: true

module PackAPI::Querying
  class ComposableQuery
    attr_reader :composer

    def initialize(initial_query, composer: :merge)
      @query = initial_query
      @composer = composer
    end

    def add(query_clause)
      @query = @query.send(composer, query_clause)
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