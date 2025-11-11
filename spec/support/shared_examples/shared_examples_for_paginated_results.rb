# frozen_string_literal: true

require 'spec_helper'

module PackAPI
  ###
  # Assumes the following variables are defined:
  # - paginated_api_query_method: the method to call
  # - paginated_resources: the resources to compare against (must be more than 1)
  #
  # If the options contain a key :model_id_attribute, then the public id will be mapped to the given model attribute.
  # Otherwise, it defaults to :external_id.
  # If the options contain a key :public_id_attribute, that will be used to access the resource identifier in the results.
  RSpec.shared_examples 'a paginated API method' do |**options|
    let(:public_id_attribute) { options[:public_id_attribute] || :id }
    let(:model_id_attribute) { options[:model_id_attribute] || :external_id }

    it 'can access the resources page-by-page' do
      returned_object_ids = []

      page_one_results = paginated_api_query_method.call(per_page: 1)
      expect(page_one_results.success).to be_truthy, -> { page_one_results.errors }
      expect(page_one_results.value).to have(1).item
      expect(page_one_results.collection_metadata.next_page_cursor).not_to be_nil
      returned_object_ids << page_one_results.value.first.send(public_id_attribute)
      next_page_cursor = page_one_results.collection_metadata.next_page_cursor

      (paginated_resources.count - 1).times do |index|
        next_page_results = paginated_api_query_method.call(per_page: 1, cursor: next_page_cursor)
        expect(next_page_results.success).to be_truthy, -> { next_page_results.errors }
        expect(next_page_results.value).to have(1).item
        if index < paginated_resources.count - 2 # if not last page
          expect(next_page_results.collection_metadata.next_page_cursor).not_to be_nil, 'next page cursor should not be nil'
          next_page_cursor = next_page_results.collection_metadata.next_page_cursor
        else
          expect(next_page_results.collection_metadata.next_page_cursor).to be_nil, 'next page cursor should be nil'
        end
        returned_object_ids << next_page_results.value.first.send(public_id_attribute)
      end

      # verify all objects were returned
      expect(returned_object_ids.sort).to match_array(paginated_resources.pluck(model_id_attribute).sort)
    end

    it 'can access the metadata (without data)' do
      results = paginated_api_query_method.call(per_page: 0)
      expect(results.success).to be_truthy, -> { results.errors }
      expect(results.value).to be_empty
      expect(results.collection_metadata).not_to be_nil
      expect(results.collection_metadata.total_items).to eq(paginated_resources.count)
    end
  end
end
