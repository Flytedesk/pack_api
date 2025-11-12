# frozen_string_literal: true

module PackAPI::Mapping
  ##
  # This class is responsible for transforming API filter names into model filters. It also produces filter definitions
  # in API terms for those filters that are supported by the model.
  class FilterMap
    attr_reader :filter_factory, :attribute_map_class

    def initialize(filter_factory:, attribute_map_class: nil)
      @filter_factory = filter_factory
      @attribute_map_class = attribute_map_class
    end

    def from_api_filters(api_filters)
      validate(api_filters)
      transform_api_attribute_filters(api_filters).merge(transform_api_custom_filters(api_filters))
    end

    def filter_definitions(filter_names: nil, **)
      supported_filters.filter_map do |filter_name, filter_class|
        next if filter_names&.exclude?(filter_name)

        api_attribute_filter_name_map.key?(filter_name) ?
          attribute_filter_definition(filter_name, filter_class) :
          other_filter_definition(filter_name, filter_class, **)
      end
    end

    private

    def attribute_filter_definition(filter_name, filter_class)
      api_filter_name = api_attribute_filter_name_map[filter_name]
      filter_class.definition.merge(name: api_filter_name)
    end

    def other_filter_definition(_filter_name, filter_class, **)
      filter_class.definition(**)
    end

    def api_attribute_filter_names
      @api_attribute_filter_names ||= attribute_map_class.nil? ?
                                        PackAPI::FrozenEmpty::ARRAY :
                                        attribute_map_class.api_type.filterable_attributes.keys
    end

    ###
    # Map from a backend filter name to an API filter name for default attribute filters.
    def api_attribute_filter_name_map
      return @api_attribute_filter_name_map if defined?(@api_attribute_filter_name_map)
      return PackAPI::FrozenEmpty::HASH if attribute_map_class.nil?

      names = {}
      api_attribute_filter_names.each { |name| names[name] = name }
      @api_attribute_filter_name_map = attribute_map_class.model_attribute_keys(names)
    end

    def validate(filters)
      invalid_filter_names = filters.keys.reject { |filter_name| valid?(filter_name) }
      raise PackAPI::InternalError, validation_error_message(invalid_filter_names) if invalid_filter_names.any?
    end

    def valid?(filter_name)
      api_filter_names.include?(filter_name)
    end

    def api_filter_names
      @api_filter_names ||= supported_filters.keys.map do |filter_name|
        api_attribute_filter_name_map.fetch(filter_name, filter_name)
      end
    end

    def validation_error_message(unsupported_filter_names)
      filter_names_string = unsupported_filter_names.map { |filter_name| "'#{filter_name}'" }.join(', ')
      api_type_name = attribute_map_class.api_type.name
      "unsupported #{'filter'.pluralize(unsupported_filter_names.size)} #{filter_names_string} for #{api_type_name}."
    end

    def transform_api_attribute_filters(api_filters)
      return api_filters if attribute_map_class.nil?

      api_attribute_filters = api_filters.select { |filter_name, _| api_attribute_filter_names.include?(filter_name) }
      attribute_map_class.model_attribute_keys(api_attribute_filters)
    end

    def transform_api_custom_filters(api_filters)
      api_filters.except(*api_attribute_filter_names)
    end

    def supported_filters
      @supported_filters ||= filter_factory.filter_classes
    end
  end
end
