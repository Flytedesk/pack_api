# frozen_string_literal: true

module PackAPI
  ###
  # Error class for passing errors from the model to the API logic
  class InternalError < StandardError
    attr_reader :object, :options

    def initialize(msg = nil, object: nil, options: {})
      super(msg)
      @object = object
      @options = options
    end

    def message
      to_s
    end

    def to_s
      return super unless object.present?

      "#{super} - #{object.inspect}"
    end
  end
end
