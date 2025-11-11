# frozen_string_literal: true

module PackAPI::Types
  class EnumFilterDefinition < BaseType
    attribute :name, Types::Symbol
    attribute :type, Types::Symbol.default(:enum)
    attribute :options, Types::Array.of(FilterOption)
    attribute :can_exclude, Types::Bool.default(false)
  end
end