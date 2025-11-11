# frozen_string_literal: true

module PackAPI::Mapping
  class ValueObjectFactory

    class << self
      attr_reader :attribute_map_registry, :value_object_attributes

      def set_attribute_map_registry(registry)
        @attribute_map_registry = registry
        @value_object_attributes ||= {}
      end

      def model_attributes_containing_value_objects(*attributes, model_class:)
        @value_object_attributes ||= {}
        @value_object_attributes[model_class] = attributes
      end
    end

    def create_object(model:, optional_attributes: nil)
      return nil if model.blank?

      options = attribute_map_options_cache.compute_if_absent(optional_attributes) { { optional_attributes: } }
      attribute_map = attribute_map(model.class, model, options)
      attribute_map.api_type.new(attribute_map.attributes)

    rescue Dry::Struct::Error => e
      model_id = model.respond_to?(:id) ? "(id #{model.id})" : ''
      raise PackAPI::InternalError, "Unable to convert #{model.class.name} #{model_id} to value object (#{e.message})"
    end

    def create_collection(models:, optional_attributes: nil)
      return [] if models.blank?

      models.filter_map { |model| create_object(model:, optional_attributes:) }
    end

    def create_errors(model:)
      attribute_map(model.class, model.errors).attributes
    end

    protected

    def attribute_map(klass, data_source, options = nil)
      attribute_map_cache.compute_if_absent(klass) { create_attribute_map(klass) }.tap do |map|
        map.data_source = data_source
        map.options = options
      end
    end

    def convert(value, optional_attributes: nil)
      value_is_collection?(value) ?
        create_collection(models: value.to_a, optional_attributes:) :
        create_object(model: value, optional_attributes:)
    end

    def value_is_collection?(value)
      value.is_a?(ActiveRecord::Associations::CollectionProxy) || value.is_a?(Array)
    end

    def create_attribute_map(model_class)
      attribute_map_class = self.class.attribute_map_registry.new.attribute_map_class(model_class)
      convert_proc = method(:convert).to_proc
      attribute_map_class.new.tap do |attribute_map|
        self.class.value_object_attributes.fetch(model_class, []).each do |attribute|
          attribute_map.register_transformation_from_model_attribute(attribute, convert_proc)
        end
      end
    end

    def attribute_map_cache
      object_cache.compute_if_absent(:attribute_maps) { Concurrent::Map.new }
    end

    def object_cache
      @object_cache ||= Concurrent::Map.new
    end

    def attribute_map_options_cache
      object_cache.compute_if_absent(:attribute_map_options) { Concurrent::Map.new }
    end
  end
end
