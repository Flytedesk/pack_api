# frozen_string_literal: true

class TestValueObjectFactory < PackAPI::Mapping::ValueObjectFactory
  set_attribute_map_registry(TestAttributeMapRegistry)
  model_attributes_containing_value_objects(:associated, :notes, model_class: BlogPost)
end