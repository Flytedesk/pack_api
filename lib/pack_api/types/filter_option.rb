# frozen_string_literal: true

module PackAPI::Types
  class FilterOption < BaseType
    attribute :label, Types::String
    attribute :value, Types::String
  end
end
