# frozen_string_literal: true

module PackAPI::Querying
  class AbstractRangeFilter < DiscoverableFilter
    attr_accessor :min_value, :max_value

    def self.type
      :range
    end

    def self.definition(**)
      PackAPI::Types::RangeFilterDefinition.new(name: filter_name)
    end

    def initialize(min_value:, max_value:)
      super()
      @min_value = min_value
      @max_value = max_value
    end

    def present?
      min_value.present? || max_value.present?
    end

    def to_h
      raise NotImplementedError unless self.class.filter_name

      { self.class.filter_name => { min_value:, max_value: } }
    end
  end
end
