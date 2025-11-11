# frozen_string_literal: true

module PackAPI::Querying
  class AttributeFilterFactory
    include Enumerable

    DATA_TYPE_REGEXP = /\S+$/
    private_constant :DATA_TYPE_REGEXP

    def self.attribute_filter_cache
      @attribute_filter_cache ||= Concurrent::Map.new
    end

    attr_reader :attribute_map_class

    def initialize(attribute_map_class)
      @attribute_map_class = attribute_map_class
    end

    def from_api_type
      filterable_attributes.each do |attribute_name, attribute_type|
        yield define_filter(attribute_name, attribute_type)
      end
    end

    private

    def filterable_attributes
      @filterable_attributes ||= attribute_map_class.api_type.filterable_attributes
    end

    def model_attribute_names
      return @model_attribute_names if defined?(@model_attribute_names)

      names = {}
      filterable_attributes.each_key { |name| names[name] = name }
      @model_attribute_names = attribute_map_class.model_attribute_keys(names).invert
    end

    def data_type(attribute_type)
      return 'Bool' if attribute_type.name.end_with?('TrueClass | FalseClass')

      attribute_type.name.include?(' | ') ?
        attribute_type.name[DATA_TYPE_REGEXP] :
        attribute_type.name
    end

    def define_filter(attribute_name, attribute_type)
      filter_name = model_attribute_names[attribute_name]
      data_type = data_type(attribute_type)
      self.class
          .attribute_filter_cache
          .compute_if_absent(filter_name) { Concurrent::Map.new }
          .compute_if_absent(data_type) do
        Class.new(AttributeFilter) do
          define_singleton_method(:filter_name) { filter_name }
          define_singleton_method(:data_type) { data_type }
        end
      end
    end
  end
end
