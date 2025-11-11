# frozen_string_literal: true

module PackAPI::Querying
  class AttributeFilter < DiscoverableFilter
    attr_accessor :value

    def self.type
      :attribute
    end

    def self.data_type
      raise NotImplementedError
    end

    def self.definition(**)
      PackAPI::Types::SimpleFilterDefinition.new(name: filter_name, data_type:)
    end

    def initialize(value)
      super()
      @value = value
    end

    def present?
      !value.nil?
    end

    def to_h
      { filter_name => value }
    end

    def apply_to(query)
      query.add(query.build.where(to_h))
    end
  end
end
