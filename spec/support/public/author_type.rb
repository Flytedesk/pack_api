# frozen_string_literal: true

class BlogPostType < PackAPI::Types::BaseType; end

class AuthorType < PackAPI::Types::BaseType
  attribute :id, ::Types::String
  attribute :name, ::Types::String
  optional_attribute :blog_posts, ::Types::Array.of(::BlogPostType)
end