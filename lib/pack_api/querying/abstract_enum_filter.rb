# frozen_string_literal: true

module PackAPI::Querying
  class AbstractEnumFilter < DiscoverableFilter
    attr_accessor :value, :exclude_param
    validates :exclude_param, inclusion: { in: %w[true false], allow_nil: true, message: 'must be either true or false' }

    def self.type
      :enum
    end

    def self.definition(**)
      PackAPI::Types::EnumFilterDefinition.new(name: filter_name,
                                      type:,
                                      options: filter_options(**),
                                      can_exclude: can_exclude?)
    end

    def self.filter_options(**)
      raise NotImplementedError
    end

    private_class_method :filter_options

    def initialize(value: nil, exclude: nil)
      super()
      @present = !value.nil?
      @value = Array.wrap(value.presence)
      @exclude_param = exclude
    end

    def present?
      @present
    end

    def exclude?
      exclude_param.to_s.downcase == 'true'
    end

    def to_h
      raise NotImplementedError unless self.class.filter_name

      payload = present? ?
                  { value: } :
                  { value: nil }
      payload[:exclude] = exclude?.to_s if self.class.can_exclude?
      { self.class.filter_name => payload }
    end

    def self.can_exclude?
      true
    end
  end
end
