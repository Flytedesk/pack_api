# frozen_string_literal: true

require 'spec_helper'

module PackAPI::Mapping
  RSpec.describe FilterMap, type: :model do
    describe 'convention-based defaults' do
      it 'infers the filter factory from the class name' do
        # when
        filter_map = BlogPostFilterMap.new
        # then
        expect(filter_map.filter_factory).to be_a(Filters::BlogPost::FilterFactory)
      end

      it 'infers the attribute map class from the class name' do
        # when
        filter_map = BlogPostFilterMap.new
        # then
        expect(filter_map.attribute_map_class).to eq(BlogPostAttributeMap)
      end

      it 'leaves the attribute map class nil when none exists by convention' do
        # given
        stub_const('Filters::Widget::FilterFactory', Class.new(PackAPI::Querying::FilterFactory))
        stub_const('WidgetFilterMap', Class.new(described_class))
        # when
        filter_map = WidgetFilterMap.new
        # then
        expect(filter_map.attribute_map_class).to be_nil
      end

      it 'honors an explicitly provided filter factory' do
        # given
        factory = PackAPI::Querying::FilterFactory.new
        # when
        filter_map = BlogPostFilterMap.new(filter_factory: factory)
        # then
        expect(filter_map.filter_factory).to eq(factory)
      end

      it 'honors an explicitly provided attribute map class' do
        # when
        filter_map = BlogPostFilterMap.new(attribute_map_class: AuthorAttributeMap)
        # then
        expect(filter_map.attribute_map_class).to eq(AuthorAttributeMap)
      end
    end
  end
end
