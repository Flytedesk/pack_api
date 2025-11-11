# frozen_string_literal: true

module PackAPI::Querying
  class AbstractNumericFilter < DiscoverableFilter
    attr_accessor :operator, :value

    def self.type
      :numeric
    end

    def self.definition(**)
      operators = [
        PackAPI::Types::FilterOption.new(label: 'Greater than', value: '>'),
        PackAPI::Types::FilterOption.new(label: 'Greater than or equal to', value: '>='),
        PackAPI::Types::FilterOption.new(label: 'Equal to', value: '='),
        PackAPI::Types::FilterOption.new(label: 'Less than or equal to', value: '<='),
        PackAPI::Types::FilterOption.new(label: 'Less than', value: '<')
      ]

      PackAPI::Types::NumericFilterDefinition.new(name: filter_name, operators:)
    end

    def initialize(operator:, value:)
      super()
      @operator = operator
      @value = value
    end

    delegate :present?, to: :value

    def to_h
      raise NotImplementedError unless self.class.filter_name

      { self.class.filter_name => { operator:, value: } }
    end
  end
end
