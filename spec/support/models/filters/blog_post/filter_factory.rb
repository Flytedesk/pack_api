# frozen_string_literal: true

module Filters
  module BlogPost
    class FilterFactory < PackAPI::Querying::FilterFactory
      def initialize
        super
        @use_default_filter = true
        register_attribute_filters(BlogPostAttributeMap)
        register_filter(AuthorFilter)
        register_filter(InvalidFilter)
      end
    end
  end
end
