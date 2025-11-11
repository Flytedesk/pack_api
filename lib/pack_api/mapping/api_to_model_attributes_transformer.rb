# frozen_string_literal: true

module PackAPI::Mapping
  ###
  # Specialized attribute transformer allowing API attributes be converted to the attribute names needed to
  # creating/updating an ActiveRecord model.
  class APIToModelAttributesTransformer < AbstractTransformer

    def execute
      result = {}
      attribute_names = NormalizedAPIAttribute.new(api_attribute_names)
      data_source.each do |api_attribute, api_value|
        normalized_api_attribute = attribute_names.normalize(api_attribute)
        model_attribute = model_attribute(normalized_api_attribute)
        model_value = model_value(normalized_api_attribute, api_value)
        result.deep_merge!({ model_attribute => model_value })
      end
      result
    end

    private

    def model_value(api_attribute, api_value)
      transform_value(api_attribute, api_value)
    end
  end
end
