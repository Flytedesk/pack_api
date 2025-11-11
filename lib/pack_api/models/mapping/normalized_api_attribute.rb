# frozen_string_literal: true

module PackAPI::Mapping
  class NormalizedAPIAttribute
    PLURAL_IDS = '_ids'
    SINGULAR_ID = '_id'

    attr_reader :api_attribute_names

    def initialize(api_attribute_names)
      @api_attribute_names = api_attribute_names
    end

    def normalize(attribute_name)
      if id_for_resource_association?(attribute_name)
        normalize_resource_association_reference(attribute_name)
      elsif id_for_collection_association?(attribute_name)
        normalize_collection_association_reference(attribute_name)
      else
        attribute_name
      end
    end

    def normalize_collection_association_reference(attribute_name)
      :"#{attribute_name.to_s.delete_suffix(PLURAL_IDS)}s"
    end

    def id_for_collection_association?(attribute_name)
      api_attribute_names.exclude?(attribute_name) && attribute_name.to_s.end_with?(PLURAL_IDS) # && api_attribute_names.include?(it_without_id_suffix)
    end

    def normalize_resource_association_reference(attribute_name)
      attribute_name.to_s.delete_suffix(SINGULAR_ID).to_sym
    end

    def id_for_resource_association?(attribute_name)
      api_attribute_names.exclude?(attribute_name) && attribute_name.to_s.end_with?(SINGULAR_ID) # && api_attribute_names.include?(it_without_id_suffix)
    end
  end
end
