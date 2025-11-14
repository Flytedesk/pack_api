# frozen_string_literal: true

module Filters
  module BlogPost
    class AuthorFilter < PackAPI::Querying::AbstractEnumFilter
      class << self
        def filter_name = :author

        private

        def filter_options(**)
          ::Author.distinct.pluck(:name).map do |value|
            PackAPI::Types::FilterOption.new(label: value, value:)
          end
        end
      end

      def apply_to(query)
        org_relation = exclude? ?
                         exclude_author_relation :
                         include_author_relation
        query.add(org_relation)
      end

      private

      def exclude_author_relation
        ::BlogPost.joins(:author).where.not(author => { name: value })
      end

      def include_author_relation
        ::BlogPost.joins(:author).where(author: { name: value })
      end
    end
  end
end
