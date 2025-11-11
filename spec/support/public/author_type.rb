# frozen_string_literal: true

class AuthorType < PackAPI::Types::BaseType
  attribute :id, ::Types::String
  attribute :name, ::Types::String
end