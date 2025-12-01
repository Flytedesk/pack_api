# frozen_string_literal: true

module PackAPI::Mapping
  ###
  # Specialized attribute transformer converting the attribute names in an ActiveRecord Error object to those
  # that should be present in the Error Hash in the API Result object.
  class ErrorHashToAPIAttributesTransformer < AbstractTransformer
    NESTED_ATTRIBUTE_ERROR_KEY = /\A(?<parent>[\w_]+)\[(?<index>\d+)\]\.(?<child>[\w_]+)\z/

    def initialize(config)
      super
      @transform_nested_attributes_with = config[:transform_nested_attributes_with]
    end

    def execute
      api_attributes = api_attribute_names.flat_map do |api_attribute|
        model_attribute = model_attribute(api_attribute)
        next unless error_present_for?(model_attribute)

        error_keys_for(model_attribute).map do |error_key|
          converted_error_key = nested_attribute_error_key?(error_key) ?
            convert_nested_attribute_error_key(error_key, api_attribute) :
            normalize_association_reference(api_attribute, model_attribute)
          [converted_error_key, data_source[error_key]]
        end
      end
      api_attributes.compact.to_h
    end

    private

    def convert_nested_attribute_error_key(error_key, parent_api_attribute)
      NESTED_ATTRIBUTE_ERROR_KEY.match(error_key) do |match_data|
        child_attribute_map_class = @transform_nested_attributes_with[parent_api_attribute]
        child_model_attribute = match_data[:child].to_sym
        child_api_attribute = child_model_attribute
        if child_attribute_map_class
          mapping = child_attribute_map_class.config[:mappings].find { |_k, v| v == child_model_attribute }
          child_api_attribute = mapping.first if mapping
        end
        "#{parent_api_attribute}[#{match_data[:index]}].#{child_api_attribute}"
      end
    end

    def nested_attribute_error_key?(error_key)
      NESTED_ATTRIBUTE_ERROR_KEY.match?(error_key.to_s)
    end

    def error_keys_for(model_attribute)
      data_source.include?(model_attribute) ?
        [model_attribute] :
        nested_attributes_with_errors(model_attribute)
    end

    def error_present_for?(model_attribute)
      data_source.include?(model_attribute) || nested_attributes_with_errors(model_attribute).any?
    end

    def nested_attributes_with_errors(parent_attribute)
      data_source.attribute_names.select { |attribute| attribute.to_s.start_with?("#{parent_attribute}[") }
    end

    def resource_association?(model_attribute)
      resource_associations.include?(model_attribute)
    end

    def collection_association?(model_attribute)
      collection_associations.include?(model_attribute)
    end

    def accepts_nested_attributes_for?(association_name)
      model_type.nested_attributes_options.key?(association_name)
    end

    def resource_associations
      @resource_associations ||= model_type.reflect_on_all_associations
                                           .reject(&:collection?)
                                           .map(&:name)
    end

    def collection_associations
      @collection_associations ||= model_type.reflect_on_all_associations
                                             .select(&:collection?)
                                             .map(&:name)
    end

    def normalize_association_reference(api_attribute, model_attribute)
      if accepts_nested_attributes_for?(model_attribute)
        api_attribute
      elsif resource_association?(model_attribute)
        normalize_resource_association_reference(api_attribute)
      elsif collection_association?(model_attribute)
        normalize_collection_association_reference(api_attribute)
      else
        api_attribute
      end
    end

    def normalize_collection_association_reference(api_attribute)
      :"#{api_attribute.to_s.singularize}_ids"
    end

    def normalize_resource_association_reference(api_attribute)
      :"#{api_attribute.to_s.singularize}_id"
    end
  end
end