# frozen_string_literal: true

module PackAPI::Querying
  module DynamicEnumFilter
    extend ActiveSupport::Concern
    class_methods do
      def type = :dynamic_enum

      def can_exclude? = false

      def search_for_options(relation:, search:) = raise NotImplementedError

      private

      def filter_options(**) = PackAPI::FrozenEmpty::ARRAY
    end
  end
end
