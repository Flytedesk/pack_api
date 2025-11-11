# frozen_string_literal: true

module PackAPI::Querying
  ##
  # This class is the base class for all discoverable filters, which can produce a definition that specifies usage.
  class DiscoverableFilter < AbstractFilter
    include ActiveModel::Validations

    def filter_name
      self.class.filter_name
    end

    def self.filter_name
      raise NotImplementedError
    end

    def type
      self.class.type
    end

    def self.type
      raise NotImplementedError
    end

    def to_h
      raise NotImplementedError
    end

    def self.definition(**)
      raise NotImplementedError
    end
  end
end
