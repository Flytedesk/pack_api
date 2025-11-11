# frozen_string_literal: true

module PackAPI::Mapping
  class AbstractTransformer
    attr_accessor :mappings, :api_type, :model_type, :data_source
    attr_reader :options

    def initialize(config)
      @mappings = config[:mappings]
      @api_type = config[:api_type]
      @model_type = config[:model_type]
      @transform_value = config[:transform_value]
      @options = {}
    end

    ###
    # @abstract
    def execute
      raise NotImplementedError
    end

    def options=(value)
      @options = value.presence || {}
    end

    protected

    def transform_value(api_attribute, value)
      @transform_value.call(api_attribute, value)
    end

    def model_attribute(api_attribute)
      return api_attribute if api_attribute.start_with?('_')

      unless mappings.key?(api_attribute)
        raise ActiveModel::UnknownAttributeError.new(@model_type.name, api_attribute)
      end

      mappings[api_attribute]
    end

    def api_attribute_names
      api_type.attribute_names
    end
  end
end
