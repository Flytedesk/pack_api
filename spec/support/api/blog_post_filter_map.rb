# frozen_string_literal: true

class BlogPostFilterMap < PackAPI::Mapping::FilterMap
  def initialize
    super(filter_factory: Filters::BlogPost::FilterFactory.new, attribute_map_class: BlogPostAttributeMap)
  end
end