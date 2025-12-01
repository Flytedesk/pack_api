# frozen_string_literal: true

class BlogPostType < PackAPI::Types::BaseType
  attribute :id, ::Types::String
  attribute :legacy_id, ::Types::String
  attribute :title, ::Types::String
  attribute :persisted, ::Types::Bool
  attribute :contents, ::Types::String.optional
  optional_attribute :associated, ::AuthorType
  optional_attribute :notes, ::Types::Array.of(CommentType)
  optional_attribute :earnings_float, ::Types::Coercible::Float
end