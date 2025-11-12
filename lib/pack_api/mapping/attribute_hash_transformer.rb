# frozen_string_literal: true

module PackAPI::Mapping
  ###
  # Specialized attribute transformer converting attribute Hashes
  #
  # Does not work with models (only Hashes)
  # Does not convert values
  # Converts model attributes to API attributes
  # Converts API attributes to model attributes
  class AttributeHashTransformer < AbstractTransformer
    def execute
      options.fetch(:contains_model_attributes, true) ?
        model_attributes_to_api_attributes :
        api_attributes_to_model_attributes
    end

    protected

    def api_attributes_to_model_attributes
      attribute_names = NormalizedAPIAttribute.new(api_attribute_names)
      result = {}
      data_source.each_key do |api_attribute|
        normalized_api_attribute = attribute_names.normalize(api_attribute)
        next unless mappings.key?(normalized_api_attribute)

        model_attribute = model_attribute(normalized_api_attribute)
        result[model_attribute] = data_source[api_attribute]
      end
      result
    end

    def model_attributes_to_api_attributes
      reversed_mappings = mappings.invert
      result = {}
      data_source.each_key do |model_attribute|
        next unless reversed_mappings.key?(model_attribute)

        api_attribute = reversed_mappings[model_attribute]
        result[api_attribute] = data_source[model_attribute]
      end
      result
    end
  end
end
