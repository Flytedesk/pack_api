# frozen_string_literal: true

module PackAPI::Mapping
  ###
  # Specialized attribute transformer converting an ActiveRecord model attributes to the attribute names needed
  # to create a ValueObject in the public API.
  class ModelToAPIAttributesTransformer < AbstractTransformer
    def options=(options)
      super
      @optional_attributes_to_include = nil
      @model_attributes_of_interest = nil
      @api_attributes_of_interest = nil
    end

    def execute
      api_attribute_names.each_with_object({}) do |api_attribute, result|
        model_attribute = model_attribute(api_attribute)
        next unless include_model_attribute?(model_attribute)

        api_value = transform_value(api_attribute, model_value(model_attribute)) if include_api_attribute?(api_attribute)
        result[api_attribute] = api_value
      end
    end

    protected

    def api_attribute_names
      api_attributes_of_interest || api_type.attribute_names
    end

    def include_api_attribute?(api_attribute)
      !optional_api_attribute?(api_attribute) || include_optional_api_attribute?(api_attribute)
    end

    def model_attributes_of_interest
      @model_attributes_of_interest ||= options[:model_attributes_of_interest]
    end

    def api_attributes_of_interest
      @api_attributes_of_interest ||= options[:api_attributes_of_interest]
    end

    def optional_attributes_to_include
      @optional_attributes_to_include ||= options[:optional_attributes]
    end

    def optional_api_attribute?(api_attribute_name)
      api_type_optional_attributes.include?(api_attribute_name)
    end

    def include_optional_api_attribute?(api_attribute_name)
      return true if api_attributes_of_interest && api_attributes_of_interest.include?(api_attribute_name)
      return false if optional_attributes_to_include.nil?
      return false if optional_attributes_to_include.respond_to?(:exclude?) &&
                      optional_attributes_to_include.exclude?(api_attribute_name)

      true
    end

    def include_model_attribute?(model_attribute)
      return true if model_attributes_of_interest.nil?

      model_attributes_of_interest.include?(model_attribute)
    end

    def api_type_optional_attributes
      @api_type_optional_attributes ||= api_type.optional_attributes || PackAPI::FrozenEmpty::ARRAY
    end

    def model_value(model_attribute)
      data_source.public_send(model_attribute)
    end
  end
end
