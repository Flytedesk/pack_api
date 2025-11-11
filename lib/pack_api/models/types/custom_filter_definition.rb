# frozen_string_literal: true

module PackAPI::Types
  class CustomFilterDefinition < BaseType
    attribute :name, Types::Symbol
    attribute :type, Types::Symbol.default(:custom)
  end
end