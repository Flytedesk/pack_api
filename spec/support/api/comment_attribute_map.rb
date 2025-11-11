# frozen_string_literal: true

class CommentAttributeMap < PackAPI::Mapping::AttributeMap
  api_type CommentType
  model_type Comment
  map :text, to: :txt
end