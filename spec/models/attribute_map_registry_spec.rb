# frozen_string_literal: true

require 'spec_helper'

module PackAPI::Mapping
  RSpec.describe AttributeMapRegistry, type: :model do
    describe '#attribute_map_class' do
      it 'returns an explicitly registered attribute map' do
        # given
        registry_class = Class.new(described_class) { register_attribute_map(AuthorAttributeMap) }
        # when/then
        expect(registry_class.new.attribute_map_class(Author)).to eq(AuthorAttributeMap)
      end

      it 'resolves <Namespace>::<Model>AttributeMap by convention when nothing is registered' do
        # given
        stub_const('Blogging::Post', Class.new)
        stub_const('Blogging::PostAttributeMap', Class.new(AttributeMap))
        stub_const('Blogging::AttributeMapRegistry', Class.new(described_class))
        # when/then
        expect(Blogging::AttributeMapRegistry.new.attribute_map_class(Blogging::Post)).to eq(Blogging::PostAttributeMap)
      end

      it 'resolves a nested (STI) model to a nested attribute map by convention' do
        # given
        stub_const('Blogging::Post::Draft', Class.new)
        stub_const('Blogging::PostAttributeMap::Draft', Class.new(AttributeMap))
        stub_const('Blogging::AttributeMapRegistry', Class.new(described_class))
        # when/then
        expect(Blogging::AttributeMapRegistry.new.attribute_map_class(Blogging::Post::Draft))
          .to eq(Blogging::PostAttributeMap::Draft)
      end

      it 'prefers an explicit registration over the convention' do
        # given
        stub_const('Blogging::Post', Class.new)
        stub_const('Blogging::PostAttributeMap', Class.new(AttributeMap))
        stub_const('Blogging::LegacyPostAttributeMap', Class.new(AttributeMap))
        stub_const('Blogging::AttributeMapRegistry', Class.new(described_class) do
          @attribute_maps = { Blogging::Post => Blogging::LegacyPostAttributeMap }
        end)
        # when/then
        expect(Blogging::AttributeMapRegistry.new.attribute_map_class(Blogging::Post))
          .to eq(Blogging::LegacyPostAttributeMap)
      end

      it 'raises when no attribute map is registered or found by convention' do
        # given
        stub_const('Blogging::Post', Class.new)
        stub_const('Blogging::AttributeMapRegistry', Class.new(described_class))
        # when/then
        expect { Blogging::AttributeMapRegistry.new.attribute_map_class(Blogging::Post) }
          .to raise_error(/No attribute map defined for Blogging::Post/)
      end
    end
  end
end
