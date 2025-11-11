# frozen_string_literal: true

module PackAPI::Types
  class NumericFilterDefinition < BaseType
    attribute :name, Types::Symbol
    attribute :type, Types::Symbol.default(:numeric)
    attribute :operators, Types::Array.of(FilterOption)
  end
end
