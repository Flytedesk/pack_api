# frozen_string_literal: true

module PackAPI::Querying
  class FilterFactory
    attr_accessor :filter_classes, :use_default_filter

    def initialize
      @filter_classes = Hash.new { |_hash, key| raise NotImplementedError, "Unsupported filter #{key}" }
    end

    def register_filter(name:, klass:)
      filter_classes[name] = klass
    end

    def create_filters(filter_hash)
      filter_objects(filter_hash).select(&:present?)
    end

    private

    def filter_objects(filter_options)
      if filter_options.is_a?(Hash)
        filter_objects_from_hash(filter_options)
      elsif use_default_filter
        [DefaultFilter.new(filter_options)]
      else
        raise ArgumentError, "Unsupported filter configuration: #{filter_options}"
      end

    end

    def filter_objects_from_hash(filter_options)
      filter_options.deep_symbolize_keys.map(&method(:filter_object_by_name))
    end

    def filter_object_by_name(filter_name, options)
      if filter_classes.key?(filter_name)
        registered_filter_object(filter_name, options)
      elsif use_default_filter
        DefaultFilter.new(filter_name => options)
      else
        raise NotImplementedError, "Unsupported filter: #{filter_name}"
      end
    end

    def registered_filter_object(filter_name, options)
      options.is_a?(Hash) ?
        filter_classes[filter_name].new(**options) :
        filter_classes[filter_name].new(options)
    rescue ArgumentError => e
      raise ArgumentError, "Invalid filter options for #{filter_name}: #{options} (#{e})"
    end
  end
end