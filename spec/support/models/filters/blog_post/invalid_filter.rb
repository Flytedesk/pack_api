# frozen_string_literal: true

module Filters
  module BlogPost
    class InvalidFilter < PackAPI::Querying::AbstractEnumFilter
      class << self
        def filter_name = :invalid

        private

        def filter_options(**) = []
      end

      def valid? = false
    end
  end
end
