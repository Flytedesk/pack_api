# frozen_string_literal: true

class AuthorAttributeMap < PackAPI::Mapping::AttributeMap
  api_type AuthorType
  model_type Author
  map :name, to: :name
  map :id, to: :external_id
  map :blog_posts
end