# frozen_string_literal: true

module PackAPI::Querying
  class DefaultFilter < AbstractFilter
    attr_accessor :arguments

    def initialize(arguments)
      super()
      @arguments = arguments
    end

    def present?
      arguments.present?
    end

    def apply_to(query)
      query.add(query.build.where(arguments))
    end
  end
end