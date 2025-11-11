# frozen_string_literal: true

module PackAPI::Types
  ###
  # Define a type that blends attributes from multiple resources into a single data structure.
  # For each kind of input resource, pass a block to the `combine_attributes` method, wherein are enumerated the
  # attributes in the output data structure which originate from that input resource.
  #
  # Example:
  #
  # class MyAggregateType < PackAPI::Types::AggregateType
  #   combine_attributes from: :resource_one do
  #     attribute :id, Types::String
  #     attribute :name, Types::String
  #   end
  #   combine_attributes from: :resource_two do
  #     attribute :description, Types::String
  #     attribute :created_at, Types::Time
  #   end
  # end
  #
  # This will create a type with attributes `id`, `name`, `description`, and `created_at`, where:
  #   - `id` and `name` come from `resource_one`
  #   - `description` and `created_at` come from `resource_two`
  #
  # For each input resource, helper methods must be defined to enable the CRUD operations:
  #   - query_<resource>s(**params) - returns a hash of resources, indexed by their IDs
  #   - get_<resource>(id) - returns a single resource, identified by its ID
  #   - create_<resource>(params) - creates a new resource and returns it
  #   - update_<resource>(id, params) - updates an existing resource and returns it
  #   - delete_<resource>(id)
  #
  # For example, for the above example, you would need to define:
  #   - query_resource_ones
  #   - get_resource_one
  #   - create_resource_one
  #   - update_resource_one
  #   - delete_resource_one
  #
  # @note: There are 2 kinds of resources:
  #   - primary resources
  #   - secondary resources
  #
  # The first resource drawn from via `combine_attributes` is considered the primary resource.
  class AggregateType < BaseType
    @attribute_sources = {}
    @attribute_sources = {}
    @next_attribute_list = nil

    class << self
      def inherited(subclass)
        subclass.instance_variable_set(:@attribute_sources, {})
        subclass.instance_variable_set(:@next_attribute_list, nil)
        super
      end

      def attribute(name, type = Undefined, &block)
        super
        @next_attribute_list << name if @next_attribute_list
      end

      def combine_attributes(from:, &block)
        @next_attribute_list = []
        block.call
        @attribute_sources[from] = @next_attribute_list
        @next_attribute_list = nil
      end

      def query(**params)
        attribute_blender.query(**params).map { new(it) }
      end

      def get(id)
        new(attribute_blender.get(id))
      end

      def update(id, params)
        new(attribute_blender.update(id, params))
      end

      def create(params)
        new(attribute_blender.create(params))
      end

      def delete(id)
        attribute_blender.delete(id)
      end

      private

      def attribute_blender
        @attribute_blender ||= AttributeBlender.new(@attribute_sources, self)
      end
    end

    class AttributeBlender
      attr_reader :attribute_sources, :combined_attributes, :aggregate_type

      def initialize(attribute_sources, aggregate_type)
        @attribute_sources = attribute_sources
        @aggregate_type = aggregate_type
        @combined_attributes = {}
      end

      def query(**params)
        primary_source, primary_resource_attributes = attribute_sources.first
        resource_method = :"query_#{primary_source}s"
        primary_resource_results = aggregate_type.send(resource_method, **params)
        combined_attributes = primary_resource_results.transform_values do |primary_resource|
          primary_resource.to_h.slice(*primary_resource_attributes)
        end
        primary_result_ids = primary_resource_results.keys
        attribute_sources.drop(1).each do |resource_name, resource_attributes|
          resource_method = :"query_#{resource_name}s"
          aggregate_type.send(resource_method, id: primary_result_ids)
                        .each do |primary_resource_id, secondary_resource|
            secondary_attributes = secondary_resource.to_h.slice(*resource_attributes)
            combined_attributes[primary_resource_id].merge!(secondary_attributes)
          end
        end

        combined_attributes.values
      end

      def get(id)
        attribute_sources.each do |resource_name, attribute_names|
          resource_method = :"get_#{resource_name}"
          resource = aggregate_type.send(resource_method, id)
          combined_attributes.merge!(resource.to_h.slice(*attribute_names))
        end
        combined_attributes
      end

      def update(id, params)
        initial_state = get(id)
        @combined_attributes = initial_state.to_h
        attribute_sources_updated = []
        attribute_sources.each do |resource_name, resource_attributes|
          resource_params = resource_params(params, resource_attributes)
          next unless resource_params.any?

          resource_method = :"update_#{resource_name}"
          resource = aggregate_type.send(resource_method, id, resource_params)
          combined_attributes.merge!(resource.to_h.slice(*resource_attributes))
        end
        combined_attributes
      rescue PackAPI::InternalError
        rollback_update(attribute_sources_updated, id, initial_state)
        raise
      end

      def create(params)
        attribute_sources_created = []
        primary_resource_id = nil
        attribute_sources.each do |resource_name, resource_attributes|
          resource_method = :"create_#{resource_name}"
          args = [resource_params(params, resource_attributes)]
          args << primary_resource_id if primary_resource_id
          resource = aggregate_type.send(resource_method, *args)
          primary_resource_id ||= resource.id
          combined_attributes.merge!(resource.to_h.slice(*resource_attributes))
        end
        combined_attributes
      rescue PackAPI::InternalError
        rollback_create(attribute_sources_created, primary_resource_id)
        raise
      end

      def delete(id)
        attribute_sources.each_key do |resource_name|
          resource_method = :"delete_#{resource_name}"
          aggregate_type.send(resource_method, id)
        rescue PackAPI::InternalError => e
          Rails.logger.error("Failed to delete #{resource_name} with id: #{id}")
          Rails.logger.error(e.backtrace.join("\n"))
        end
      end

      private

      def resource_params(params, resource_attributes)
        normalizer = PackAPI::Mapping::NormalizedAPIAttribute.new(resource_attributes)
        params.filter { |key| resource_attributes.include?(normalizer.normalize(key)) }
      end

      def rollback_update(attribute_sources_updated, id, initial_state)
        attribute_sources_updated.reverse_each do |resource_name|
          resource_method = :"update_#{resource_name}"
          attribute_names = attribute_sources[resource_name]
          aggregate_type.send(resource_method, id, initial_state.to_h.slice(*attribute_names))
        end
      end

      def rollback_create(attribute_sources_created, primary_resource_id)
        attribute_sources_created.reverse_each do |resource_name|
          resource_method = :"delete_#{resource_name}"
          aggregate_type.send(resource_method, primary_resource_id)
        end
      end
    end
  end
end