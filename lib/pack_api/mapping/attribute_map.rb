# frozen_string_literal: true

###
# Map (convert) the names of attributes presented on one side of an API to those required on the other side.
# Handles 3 scenarios:
#
#   1. create/update API endpoints
#       IN: attribute Hash with names conforming to the ValueObject type attributes*
#       OUT: attribute Hash with names conforming to the ActiveRecord model type
#
#       * generally true; except when it's not. For example, if the ValueObject type has an attribute
#         named "user", and the ActiveRecord model has an attribute named "user", typically this is set during
#         create/update calls by passing in the "user_id" attribute.
#
#  2. converting an ActiveRecord model as a ValueObject
#      IN: ActiveRecord model instance
#      OUT: attribute Hash with names conforming to the ValueObject type attributes
#
#  3. converting an ActiveModel::Errors instance to an attribute Hash
#     IN: ActiveModel::Errors instance
#     OUT: attribute Hash with names conforming to the ValueObject type attributes*
#
#     * generally true; except when it's not. For example, if the ValueObject type has an attribute
#       named "user", and the ActiveRecord model has an attribute named "user", typically this is set during
#       create/update calls by passing in the "user_id" attribute. Therefore, the error hash will have to
#       associate the error with the "user_id" attribute (not the "user" attribute).
module PackAPI::Mapping
  class AttributeMap
    FROZEN_EMPTY_HASH = {}.freeze

    attr_reader :config, :options

    class << self
      def map(source_attr, to: nil, from_api_attribute: nil, from_model_attribute: nil, readonly: nil, transform_nested_attributes_with: nil)
        @mappings ||= {}
        @from_api_attributes ||= {}
        @from_model_attributes ||= {}
        @transform_nested_attributes_with ||= {}
        @mappings[source_attr] = to || source_attr
        @from_model_attributes[source_attr] = from_model_attribute if from_model_attribute.present?
        @from_api_attributes[source_attr] = from_api_attribute if from_api_attribute.present?
        @transform_nested_attributes_with[source_attr] = transform_nested_attributes_with if transform_nested_attributes_with.present?
        if readonly
          @from_api_attributes[source_attr] = ->(*) { raise PackAPI::InternalError, "Unable to modify read-only attribute '#{source_attr}'" }
        end
      end

      def api_type(api_type = nil)
        return @api_type unless api_type

        @api_type = api_type
      end

      def model_type(model_type = nil)
        return @model_type unless model_type

        @model_type = model_type
      end

      def config
        {
          mappings: @mappings,
          from_api_attributes: @from_api_attributes,
          from_model_attributes: @from_model_attributes,
          transform_nested_attributes_with: @transform_nested_attributes_with,
          api_type: @api_type,
          model_type: @model_type
        }
      end
    end

    def self.model_attribute_keys(hash)
      options = { contains_model_attributes: false,
                  transformer_type_for_source: AttributeHashTransformer.name }
      new(hash.symbolize_keys, options).attributes
    end

    def self.api_attribute_keys(hash)
      options = { contains_model_attributes: true,
                  transformer_type_for_source: AttributeHashTransformer.name }
      new(hash.symbolize_keys, options).attributes
    end

    DEFAULT_OPTIONS = { optional_attributes: nil }.freeze
    private_constant :DEFAULT_OPTIONS

    def initialize(data_source = nil, options = nil)
      @options = DEFAULT_OPTIONS
      @config = self.class.config

      self.options = options
      self.data_source = data_source
    end

    def from_model_attributes
      @from_model_attributes ||= config[:from_model_attributes].transform_values do |proc_or_method_name|
        ValueTransformationChain.new([ValueTransformation.new(self.class, proc_or_method_name, options)])
      end
    end

    def from_api_attributes
      return @from_api_attributes if defined?(@from_api_attributes)

      @from_api_attributes = config[:from_api_attributes].transform_values do |proc_or_method_name|
        ValueTransformationChain.new([ValueTransformation.new(self.class, proc_or_method_name, options)])
      end

      config[:transform_nested_attributes_with].each do |source_attr, attribute_map_class|
        @from_api_attributes[source_attr] ||= ValueTransformationChain.new([])
        @from_api_attributes[source_attr].transformations << ValueTransformation.new(
          self.class, :convert_nested_attribute, { attribute_map_class: attribute_map_class }
        )
      end

      @from_api_attributes
    end

    def data_source=(data_source)
      transformer_type = transformer_type_for_source(data_source)
      unless @transformer.is_a?(transformer_type)
        @transformer = transformer_type.new(config_for_adapter_type(transformer_type))
      end
      @transformer.data_source = data_source
      @transformer.options = @options
    end

    def data_source
      @transformer&.data_source
    end

    def options=(new_options)
      return if new_options == @provided_options

      @provided_options = new_options
      @options = @provided_options ?
                   DEFAULT_OPTIONS.merge(@provided_options) :
                   DEFAULT_OPTIONS
      from_model_attributes.each_value { |transformation| transformation.kwargs = options }
      @transformer&.options = options
    end

    def register_transformation_from_model_attribute(source_attr, proc_or_method_name)
      from_model_attributes[source_attr] ||= ValueTransformationChain.new([])
      transformation = ValueTransformation.new(self.class, proc_or_method_name, options)
      from_model_attributes[source_attr].transformations << transformation
    end

    def attributes
      @transformer.execute
    end

    def api_type
      self.class.api_type
    end

    def model_type
      self.class.model_type
    end

    private

    def convert_nested_attribute(parent_attribute_value, attribute_map_class:)
      attribute_map = attribute_map_class.new
      if parent_attribute_value.is_a?(Array)
        parent_attribute_value.map do |nested_attributes|
          attribute_map.data_source = nested_attributes
          attribute_map.attributes
        end
      else
        attribute_map.data_source = parent_attribute_value
        attribute_map.attributes
      end
    end

    def transformer_type_for_source(source)
      if options.key?(:transformer_type_for_source)
        options[:transformer_type_for_source].constantize
      elsif source.nil?
        NullTransformer
      elsif source.is_a?(Hash)
        APIToModelAttributesTransformer
      elsif source.is_a?(ActiveModel::Errors)
        ErrorHashToAPIAttributesTransformer
      elsif source.is_a?(ActiveModel::AttributeAssignment)
        ModelToAPIAttributesTransformer
      else
        raise "Unknown source #{source}"
      end
    end

    def config_for_adapter_type(adapter_type)
      if [ErrorHashToAPIAttributesTransformer, ModelToAPIAttributesTransformer].include?(adapter_type)
        transform_value = method(:transform_value_for_api)
        config.merge(transform_value:)
      elsif adapter_type == APIToModelAttributesTransformer
        transform_value = method(:transform_value_for_model)
        config.merge(transform_value:)
      else
        config
      end
    end

    def transform_value_for_api(api_attribute, model_value)
      from_model_attributes.key?(api_attribute) ?
        from_model_attributes[api_attribute].call(self, model_value) :
        model_value
    end

    def transform_value_for_model(api_attribute, api_value)
      from_api_attributes.key?(api_attribute) ?
        from_api_attributes[api_attribute].call(self, api_value) :
        api_value
    end

    class ValueTransformation
      attr_reader :proc, :instance_method

      def initialize(klass, proc_or_method_name, kwargs = nil)
        if proc_or_method_name.is_a?(Proc)
          @proc = proc_or_method_name
        else
          @instance_method = klass.instance_method(proc_or_method_name)
        end
        self.kwargs = kwargs
      end

      def call(attribute_map, attribute_value)
        proc ?
          attribute_map.instance_exec(attribute_value, **@kwargs, &proc) :
          attribute_map.send(instance_method.name, attribute_value, **@kwargs)
      end

      def kwargs=(new_kwargs)
        @kwargs = supported_kwargs(new_kwargs)
      end

      private

      def supported_kwargs(kwargs)
        return FROZEN_EMPTY_HASH if kwargs.blank?

        kwargs.select { |kwarg| parameters.any? { |parameter| parameter.last == kwarg } }
      end

      def parameters
        @parameters ||= (proc || instance_method).parameters
      end
    end

    class ValueTransformationChain
      attr_reader :transformations
      def initialize(transformations)
        @transformations = transformations
      end

      def kwargs=(new_kwargs)
        transformations.each { it.kwargs = new_kwargs }
      end

      def call(attribute_map, attribute_value)
        transformations.reduce(attribute_value) do |prev_result, next_transformation|
          next_transformation.call(attribute_map, prev_result)
        end
      end
    end

  end
end
