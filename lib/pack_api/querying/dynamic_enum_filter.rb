# frozen_string_literal: true

module PackAPI::Querying
  module DynamicEnumFilter
    extend ActiveSupport::Concern
    class_methods do
      def type = :dynamic_enum

      ###
      # Retrieve options for this filter based on user input.
      # @param relation [ActiveRecord::Relation] The base relation to query against for options.
      # @param search [String, nil] An optional search term to filter options by (using wildcard matching)
      # @param value [String, Array<String>, nil] An optional value or array of values to filter options by (exact match)
      def dynamic_options(relation:, search: nil, value: nil) = raise NotImplementedError

      private

      ###
      # Static filter options is an empty array.
      def filter_options(**) = PackAPI::FrozenEmpty::ARRAY
    end
  end
end
