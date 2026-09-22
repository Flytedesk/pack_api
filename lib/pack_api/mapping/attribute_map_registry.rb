# frozen_string_literal: true

module PackAPI::Mapping
  ###
  # Finds the attribute map for a model class. A registry named "<Namespace>::AttributeMapRegistry" resolves
  # "<Namespace>::<Model>AttributeMap" by convention (nested models resolve to nested attribute maps, e.g.
  # <Namespace>::Post::Draft -> <Namespace>::PostAttributeMap::Draft); register_attribute_map covers the exceptions.
  class AttributeMapRegistry

    class << self
      def attribute_maps
        @attribute_maps ||= {}
      end

      def register_attribute_map(attribute_map_class)
        attribute_maps[attribute_map_class.model_type] = attribute_map_class
      end
    end

    def attribute_map_class(model_class)
      self.class.attribute_maps[model_class] ||
        conventional_attribute_map_class(model_class) ||
        raise("No attribute map defined for #{model_class}")
    end

    private

    def conventional_attribute_map_class(model_class)
      namespace = self.class.name.deconstantize
      model, *nested = model_class.name.delete_prefix("#{namespace}::").split('::')
      [namespace.presence, "#{model}AttributeMap", *nested].compact.join('::').safe_constantize
    end
  end
end
