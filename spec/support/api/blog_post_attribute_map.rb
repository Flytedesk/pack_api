# frozen_string_literal: true

class BlogPostAttributeMap < PackAPI::Mapping::AttributeMap
  api_type BlogPostType
  model_type BlogPost

  # API attributes with the same name as the model attribute (title) need no map

  # example of API attribute ending in "_id" (mapped explicitly for documentation; the default would be identical)
  map :legacy_id

  map :contents, from_model_attribute: ->(attachment) { attachment&.blob }

  # example API attribute mapped to a model attribute of a different name
  map :id, to: :external_id

  # example of API attribute mapped to a model method (unidirectional)
  map :persisted, to: :persisted?, readonly: true

  # example of API association mapped to a model association
  # (the association_id can also be passed in, and reported on during error cases)
  map :associated, to: :author,
      from_api_attribute: ->(author_id) { Author.find_by(external_id: author_id) }

  map :notes, to: :comments, transform_nested_attributes_with: CommentAttributeMap

  # example of OPTIONAL API attribute (association) mapped to a model method (bidirectional)
  map :earnings_float, to: :earnings_float
end