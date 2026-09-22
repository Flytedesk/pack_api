# frozen_string_literal: true

require 'spec_helper'

module PackAPI::Querying
  RSpec.describe FilterFactory, type: :model do
    let(:factory) { described_class.new }

    describe '#register_filter' do
      it 'registers a filter class under its own filter_name' do
        # when
        factory.register_filter(Filters::BlogPost::AuthorFilter)
        # then
        expect(factory.filter_classes[:author]).to eq(Filters::BlogPost::AuthorFilter)
      end

      it 'registers a filter class under an explicit name' do
        # when
        factory.register_filter(Filters::BlogPost::AuthorFilter, name: :writer)
        # then
        expect(factory.filter_classes[:writer]).to eq(Filters::BlogPost::AuthorFilter)
      end
    end

    describe '#register_attribute_filters' do
      it 'registers an attribute filter for each filterable attribute of the api type' do
        # when
        factory.register_attribute_filters(BlogPostAttributeMap)
        # then
        expect(factory.filter_classes.keys).to contain_exactly(:external_id, :title)
      end

      it 'registers filters keyed by model attribute name' do
        # when
        factory.register_attribute_filters(BlogPostAttributeMap)
        # then
        expect(factory.filter_classes[:external_id]).to be < AttributeFilter
      end
    end
  end
end
