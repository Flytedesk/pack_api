# frozen_string_literal: true

module PackAPI::Types
  class BaseType < Dry::Struct
    @optional_attributes = []
    @filterable_attributes = {}

    def self.inherited(subclass)
      subclass.instance_variable_set(:@optional_attributes, [])
      super
    end

    def self.optional_attribute(name, type = Undefined, &block)
      attribute?(name, type.optional, &block)
      @optional_attributes << name
    end

    def self.optional_attributes
      @optional_attributes.to_a
    end

    def to_data(**other_attributes)
      merged_attributes = to_h.merge(other_attributes)
      Data.define(*merged_attributes.keys).new(**merged_attributes)
    end

    def merge(**other_attributes)
      self.class.new(to_h.merge(other_attributes))
    end

    ##
    # This method returns a mapping of attribute names to `Dry::Type::*` objects that describe the attributes that have
    # been designated as filterable, as in the following example:
    #   attribute :id, Types::String.meta(filterable: true)
    #
    # NOTE: According to the documentation, `Dry::Types::Schema::Key` is part of a private API, but we haven't found a
    # better way to access an attribute's metadata or type:
    # - https://www.rubydoc.info/github/dry-rb/dry-types/main/Dry/Types/Schema/Key
    # - https://discourse.dry-rb.org/t/how-to-access-meta-fields-in-structs/989
    def self.filterable_attributes
      schema.keys.each_with_object({}) do |schema_key, result|
        result[schema_key.name] = schema_key.type if schema_key.meta[:filterable]
      end
    end
  end
end
