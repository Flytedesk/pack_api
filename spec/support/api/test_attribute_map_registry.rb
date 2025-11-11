# frozen_string_literal: true

class TestAttributeMapRegistry < PackAPI::Mapping::AttributeMapRegistry
  register_attribute_map(BlogPostAttributeMap)
  register_attribute_map(AuthorAttributeMap)
  register_attribute_map(CommentAttributeMap)
end