# frozen_string_literal: true

module PackAPI::Types
  class SimpleFilterDefinition < BaseType
    attribute :name, Types::Symbol
    attribute :type, Types::Symbol.default(:simple)
    attribute :data_type, Types::String
  end
end
