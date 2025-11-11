# frozen_string_literal: true

module PackAPI::Querying
  class AbstractBooleanFilter < DiscoverableFilter
    attr_accessor :value

    YES_VALUE = 'Yes'
    NO_VALUE = 'No'
    NOT_APPLICABLE_VALUE = ''

    def self.type
      :tri_state_boolean
    end

    def self.definition(**)
      options = [
        PackAPI::Types::FilterOption.new(label: 'N/A', value: NOT_APPLICABLE_VALUE),
        PackAPI::Types::FilterOption.new(label: 'Yes', value: YES_VALUE),
        PackAPI::Types::FilterOption.new(label: 'No', value: NO_VALUE)
      ]

      PackAPI::Types::BooleanFilterDefinition.new(name: filter_name, type:, options:)
    end

    def initialize(value:)
      super()
      @value = value
    end

    delegate :present?, to: :value

    def to_h
      raise NotImplementedError unless self.class.filter_name

      { self.class.filter_name => { value: } }
    end
  end
end
