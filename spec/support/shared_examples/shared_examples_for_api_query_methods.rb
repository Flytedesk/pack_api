# frozen_string_literal: true

require 'spec_helper'

module PackAPI
  ###
  # Assumes the following variables are defined:
  # - api_query_method: the method to call
  # - resources: the resources to compare against (must be more than 1)
  #
  # If the options contain a key :model_id_attribute, then the public id will be mapped to the given model attribute.
  # Otherwise, it defaults to :external_id.
  #
  # If the options contain a key: `supports_search` set to `true`, then
  # the following variables are also required:
  # - search_terms: a string, representing the search terms to use
  # - matched_resources: *at least 2* resources that will be returned by the search
  RSpec.shared_examples 'an API query method' do |**options|
    let(:model_id_attribute) { options[:model_id_attribute] || :external_id }

    context 'with no id' do
      it 'returns a successful result with all resources' do
        # when
        result = api_query_method.call

        # then
        expect(result.success).to be_truthy, -> { result.errors }
        expect(result.errors).to be_nil
        expect(result.value).not_to be_nil
        expect(result.value).to have(resources.count).items
        expect(result.value.pluck(:id).sort).to match_array(resources.pluck(model_id_attribute).sort)
      end
    end

    context 'with nil id' do
      it 'returns a successful result with all resources' do
        # when
        result = api_query_method.call(id: nil)

        # then
        expect(result.success).to be_truthy, -> { result.errors }
        expect(result.errors).to be_nil
        expect(result.value).not_to be_nil
        expect(result.value).to have(resources.count).items
        expect(result.value.pluck(:id).sort).to match_array(resources.pluck(model_id_attribute).sort)
      end
    end

    context 'with an empty string id' do
      it 'returns a successful result with no resources' do
        # when
        result = api_query_method.call(id: '')

        # then
        expect(result.success).to be_truthy, -> { result.errors }
        expect(result.errors).to be_nil
        expect(result.value).not_to be_nil
        expect(result.value).to have(0).items
      end
    end

    context 'with an empty array id' do
      it 'returns a successful result with no resources' do
        # when
        result = api_query_method.call(id: [])

        # then
        expect(result.success).to be_truthy, -> { result.errors }
        expect(result.errors).to be_nil
        expect(result.value).not_to be_nil
        expect(result.value).to have(0).items
      end
    end

    context 'with an unknown id' do
      it 'returns an empty success result' do
        result = api_query_method.call(id: 'unknown')
        expect(result.success).to be_truthy, -> { result.errors }
        expect(result.value).to have(0).items
      end
    end

    context 'with a known id' do
      it 'returns a success result with the resource' do
        value = api_query_method.call(id: resources.first[model_id_attribute])
        expect(value.success).to be_truthy, -> { result.errors }
        expect(value.value).to have(1).item
        expect(value.value.first.id).to eq(resources.first[model_id_attribute])
      end
    end

    it_behaves_like 'a paginated API method', model_id_attribute: options[:model_id_attribute] || :external_id do
      let(:paginated_api_query_method) { api_query_method }
      let(:paginated_resources) { resources }
    end

    context 'with search terms', if: options[:supports_search] do
      it 'limits results to matching resources' do
        # when
        result = api_query_method.call(search_terms:)
        # then
        expect(result.success).to be_truthy, -> { result.errors }
        expect(result.value).to have(matched_resources.size).item
        matched_resource_ids = matched_resources.pluck(model_id_attribute)
        result.value.each do |resource|
          expect(matched_resource_ids).to include(resource.id)
        end
      end

      it_behaves_like 'a paginated API method', model_id_attribute: options[:model_id_attribute] || :external_id do
        let(:paginated_api_query_method) do
          ->(**args) { api_query_method.call(search_terms:, **args) }
        end
        let(:paginated_resources) { matched_resources }
      end
    end

    it 'supports sorting by API attributes only' do
      resources.each_with_index { |resource, index| resource.update(model_id_attribute => format('%02d', index + 1)) }
      # when - sort by API attribute `id` in descending order
      results = api_query_method.call(sort: { id: :desc })
      # then - results should be in model_id_attribute in descending order
      expect(results.success).to be_truthy, -> { results.errors }
      expect(results.value.first.id).to eq(resources.last[model_id_attribute])
      expect(results.value.last.id).to eq(resources.first[model_id_attribute])
    end
  end
end
