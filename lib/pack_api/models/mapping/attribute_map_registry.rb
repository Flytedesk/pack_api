# frozen_string_literal: true

module PackAPI::Mapping
  class AttributeMapRegistry

    class << self
      attr_reader :attribute_maps

      def register_attribute_map(attribute_map_class)
        @attribute_maps ||= {}
        @attribute_maps[attribute_map_class.model_type] = attribute_map_class
      end
    end

    def attribute_map_class(model_class)
      raise "No attribute map defined for #{model_class}" unless self.class.attribute_maps.key?(model_class)

      self.class.attribute_maps[model_class]
    end
  end
end
