# frozen_string_literal: true

module PackAPI::Types
  class Result < Dry::Struct
    attribute :success, Types::Bool
    attribute? :value, Types::Any.optional
    attribute? :errors, Types::Hash.optional
    attribute? :collection_metadata, CollectionResultMetadata.optional

    def self.from_request_error(message, model: nil)
      new(success: false, errors: { request: [message] }, value: model)
    end

    def self.from_collection(models:,
                             value_object_factory:,
                             optional_attributes: nil,
                             paginator: nil,
                             sort: nil,
                             current_page_snapshot_cursor: nil)
      value = value_object_factory.create_collection(models:, optional_attributes:)
      if paginator.present?
        collection_metadata = CollectionResultMetadata.from_paginator(paginator, sort, current_page_snapshot_cursor)
      end

      new(
        success: true,
        value:,
        collection_metadata:
      )
    end

    def self.from_model(model:, value_object_factory:, optional_attributes: nil)
      if model.errors.present?
        errors = value_object_factory.create_errors(model:)
        errors[:request] = model.errors[:base] if model.errors[:base].present?
        new(
          success: false,
          errors:
        )
      else
        new(
          success: true,
          value: value_object_factory.create_object(model:, optional_attributes:)
        )
      end
    end

    def attribute_error_string(attribute)
      return '' if errors.nil? || errors[attribute].blank?

      errors[attribute]&.join(', ')
    end

    def request_error_string
      return '' if errors.nil? || errors[:request].blank?

      "#{errors[:request]&.join(', ')}."
    end

    def error_string
      return '' if errors.nil?

      one_message_per_error = errors.map do |attribute, errors|
        "#{attribute.to_s.titleize}: #{Array.wrap(errors).join(', ')}"
      end

      one_message_per_error.join(', ')
    end
  end
end
