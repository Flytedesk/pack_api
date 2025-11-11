# frozen_string_literal: true

module PackAPI::Types
  class BooleanFilterDefinition < BaseType
    attribute :name, Types::Symbol
    attribute :type, Types::Symbol.default(:tri_state_boolean)
    attribute :options, Types::Array.of(FilterOption)
  end
end
