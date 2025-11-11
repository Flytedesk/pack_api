# frozen_string_literal: true

module Filters
  module BlogPost
    class FilterFactory < PackAPI::Querying::FilterFactory
      def initialize
        super
        @use_default_filter = false
        PackAPI::Querying::AttributeFilterFactory.new(BlogPostAttributeMap).from_api_type do |klass|
          register_filter(name: klass.filter_name, klass:)
        end
        register_filter(name: AuthorFilter.filter_name, klass: AuthorFilter)
      end
    end
  end
end
