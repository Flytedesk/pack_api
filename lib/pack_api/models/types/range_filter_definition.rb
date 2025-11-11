# frozen_string_literal: true

module PackAPI::Types
  class RangeFilterDefinition < BaseType
    attribute :name, Types::Symbol
    attribute :type, Types::Symbol.default(:range)
    attribute :range_start_constraints, Types::Hash.schema(min: Types::Any.optional, max: Types::Any.optional).optional
    attribute :range_end_constraints, Types::Hash.schema(min: Types::Any.optional, max: Types::Any.optional).optional
  end
end
