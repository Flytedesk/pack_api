# frozen_string_literal: true

require 'spec_helper'

module PackAPI::Mapping
  RSpec.describe AttributeMap, type: :model do
    let(:author) { Author.new(name: 'Alex', external_id: '9') }
    let(:blog_post_contents_file) { "#{File.dirname(__FILE__)}/../fixtures/files/blog_post_contents.txt" }
    let(:blog_post_contents) { Rack::Test::UploadedFile.new(blog_post_contents_file, 'text/plain') }
    let(:blog_post) { BlogPost.new(title: 'Testing', external_id: '1', earnings: 10.0, author:, contents: blog_post_contents) }

    context 'from API attributes to model attributes' do
      let(:test_value) { 'Testing' }
      let(:input) { { api_attribute => test_value } }
      let(:attribute_map) { BlogPostAttributeMap.new(input) }

      context 'with unknown attribute' do
        let(:api_attribute) { :foo }

        it 'raises an error' do
          # when
          expected_error_message = /unknown attribute 'foo' for BlogPost./
          expect { attribute_map.attributes }.to raise_error(PackAPI::InternalError, expected_error_message)
        end
      end

      context 'with read-only attributes' do
        let(:api_attribute) { :persisted }
        let(:test_value) { 'Testing' }

        it 'raises an error' do
          expect { attribute_map.attributes }.to raise_error(PackAPI::InternalError, /read-only attribute/)
        end
      end

      context 'with attributes mapped to same name' do
        let(:api_attribute) { :title }
        let(:model_attribute) { :title }

        it 'contains model attributes' do
          # when
          result = attribute_map.attributes
          # then
          expect(result[model_attribute]).to eq(test_value)
        end
      end

      context 'with attributes mapped to different name' do
        let(:api_attribute) { :id }
        let(:model_attribute) { :external_id }

        it 'contains model attributes' do
          # when
          result = attribute_map.attributes
          # then
          expect(result[model_attribute]).to eq(test_value)
        end
      end

      context 'with attributes mapped to a model method (bidirectional)' do
        let(:api_attribute) { :earnings_float }
        let(:model_attribute) { :earnings_float }
        let(:test_value) { 10.0 }

        it 'contains model attributes' do
          # when
          result = attribute_map.attributes
          # then
          expect(result[model_attribute]).to eq(test_value)
        end
      end

      context 'with attributes mapped to a singular model association (eg belongs_to)' do
        let(:other_author) { Author.create(name: 'Piper', external_id: '7') }
        let(:test_value) { other_author.external_id }
        let(:api_attribute) { :associated_id }
        let(:model_attribute) { :author }

        it 'contains model attributes' do
          # when
          result = attribute_map.attributes
          # then
          expect(result).to include(model_attribute)
        end

        it 'performs transformation' do
          # when
          result = attribute_map.attributes
          # then
          expect(result[model_attribute]).to eq(other_author)
        end
      end

      context 'with attributes mapped to a plural model association (eg has_many)' do
        let(:attribute_map) { AuthorAttributeMap.new({ blog_post_ids: [1, 2, 3] }) }

        it 'contains model attributes' do
          # when
          result = attribute_map.attributes
          # then
          expect(result).to include(:blog_posts)
        end
      end

      context 'with attributes ending in _id' do
        let(:api_attribute) { :legacy_id }
        let(:model_attribute) { :legacy_id }
        let(:test_value) { blog_post.id }

        it 'contains model attributes' do
          # when
          result = attribute_map.attributes
          # then
          expect(result).to include(model_attribute)
        end
      end

      context 'with attributes for has_many nested attributes' do
        let(:test_value) { [{ text: 'Note 1', _destroy: 1 }, { text: 'Note 2' }] }
        let(:api_attribute) { :notes }
        let(:model_attribute) { :comments }

        it 'contains model attributes' do
          # when
          result = attribute_map.attributes
          # then
          expect(result).to include(model_attribute)
          expect(result[model_attribute].first).to include(:txt)
          expect(result[model_attribute].second).to include(:txt)
        end

        it 'passes along the _destroy attribute' do
          # when
          result = attribute_map.attributes
          # then
          expect(result[model_attribute].first).to include(:_destroy)
        end
      end
    end

    context 'from model object to API attributes' do
      let(:attribute_map) { BlogPostAttributeMap.new(blog_post, { optional_attributes: [:associated, :notes, :earnings_float] }) }

      context 'with attributes mapped to same name' do
        let(:api_attribute) { :title }
        let(:model_attribute) { :title }
        let(:test_value) { 'Testing' }

        it 'contains API attributes' do
          # when
          result = attribute_map.attributes
          # then
          expect(result[api_attribute]).to eq(test_value)
        end
      end

      it 'omits unmapped model attributes' do
        # when
        result = attribute_map.attributes
        # then
        expect(result).not_to include(:tags)
      end

      context 'with attributes mapped to a different name' do
        let(:api_attribute) { :id }
        let(:model_attribute) { :external_id }
        let(:test_value) { '1' }

        it 'contains API attributes' do
          # when
          result = attribute_map.attributes
          # then
          expect(result[api_attribute]).to eq(test_value)
        end
      end

      context 'with attributes mapped to a model method (bidirectional)' do
        let(:api_attribute) { :earnings_float }
        let(:model_attribute) { :earnings_float }
        let(:test_value) { 10.0 }

        it 'contains API attributes' do
          # when
          result = attribute_map.attributes
          # then
          expect(result[api_attribute]).to eq(test_value)
        end
      end

      context 'with attributes mapped to an ActiveModel association' do
        let(:test_value) { AuthorType.new(id: author.external_id, name: author.name) }
        let(:api_attribute) { :associated }
        let(:model_attribute) { :author }

        context '(included)' do
          it 'contains API attributes set' do
            # when
            result = attribute_map.attributes
            # then
            expect(result).to include(api_attribute)
            expect(result[api_attribute]).not_to be_nil
            expect(result[api_attribute].name).to eq(test_value.name)
          end
        end

        context '(excluded)' do
          let(:attribute_map) { BlogPostAttributeMap.new(blog_post, { optional_attributes: nil }) }

          it 'contains API attributes set to nil' do
            # when
            result = attribute_map.attributes
            # then
            expect(result[api_attribute]).to be_nil
          end
        end

      end

      context 'with model_attributes_of_interest' do
        let(:options) { { optional_attributes: [:associated], model_attributes_of_interest: [:author, :external_id] } }
        let(:attribute_map) { BlogPostAttributeMap.new(blog_post, options) }

        it 'contains only the specified attributes' do
          # when
          result = attribute_map.attributes
          # then
          expect(result).to have(2).items
          expect(result).to include(:id)
          expect(result).to include(:associated)
        end
      end

      context 'with multiple model value transformations' do
        it 'contains values transformed by multiple methods' do
          # given
          attribute_map = BlogPostAttributeMap.new(blog_post)
          attribute_map.register_transformation_from_model_attribute(:title, ->{ it.upcase })
          attribute_map.register_transformation_from_model_attribute(:title, ->{ it.reverse })
          attribute_map.register_transformation_from_model_attribute(:title, ->{ "** #{it} **" })
          # when
          result = attribute_map.attributes
          # then
          expect(result[:title]).to eq('** GNITSET **')
        end
      end
    end

    context 'from error hash to API attributes' do
      let(:attribute_map) { BlogPostAttributeMap.new(blog_post.errors) }

      it 'only includes the attributes having errors' do
        # given
        blog_post.errors.add(:external_id, 'is required')
        # when
        result = attribute_map.attributes
        # then
        expect(result).to have(1).item, -> { result.inspect }
      end

      it 'only includes the API attributes' do
        # given
        blog_post.errors.add(:tags, 'is required')
        # when
        result = attribute_map.attributes
        # then
        expect(result).not_to include(:tags)
      end

      context 'with attributes mapped to same name' do
        it 'contains API attributes' do
          # given
          blog_post.errors.add(:title, 'is required')
          # when
          result = attribute_map.attributes
          # then
          expect(result[:title]).to be_present
        end
      end

      context 'with attributes mapped to different name' do
        it 'contains API attributes' do
          # given
          blog_post.errors.add(:external_id, 'is required')
          # when
          result = attribute_map.attributes
          # then
          expect(result[:id]).to be_present
        end
      end

      context 'with attributes mapped to an associated resource' do
        it 'contains API attributes' do
          # given
          blog_post.errors.add(:author, 'is required')
          # when
          result = attribute_map.attributes
          # then
          expect(result).to include(:associated_id)
        end
      end

      context 'with attributes mapped to an associated collection' do
        let(:attribute_map) { AuthorAttributeMap.new(author.errors) }

        it 'contains API attributes' do
          # given
          author.errors.add(:blog_posts, 'too many')
          # when
          result = attribute_map.attributes
          # then
          expect(result).to include(:blog_post_ids)
        end
      end

      context 'with attributes mapped to an associated collection (accepts_nested_attributes_for)' do
        it 'contains API attributes' do
          # given
          blog_post.errors.add(:comments, 'is required')
          # when
          result = attribute_map.attributes
          # then
          expect(result).to include(:notes)
        end
      end

      context 'with attributes ending in _id' do
        it 'contains API attributes' do
          # given
          blog_post.errors.add(:legacy_id, 'is required')
          # when
          result = attribute_map.attributes
          # then
          expect(result).to include(:legacy_id)
        end
      end

      context 'with attributes for has_many nested attributes' do
        it 'contains API attributes' do
          # given
          blog_post.errors.add(:'comments[0].txt', 'is required')
          # when
          result = attribute_map.attributes
          # then
          expect(result).to include('notes[0].text')
          expect(result['notes[0].text']).to eq(['is required'])
        end
      end
    end

    context 'for sort hash (Model->API)' do
      let(:options) { { transformer_type_for_source: AttributeHashTransformer.name, contains_model_attributes: true } }
      let(:source_data) { { legacy_id: blog_post.legacy_id, title: blog_post.title, external_id: blog_post.external_id } }
      let(:attribute_map) { BlogPostAttributeMap.new(source_data, options) }

      it 'generates API attribute keys (leaving values unchanged)' do
        # when
        result = attribute_map.attributes
        # then
        expect(result[:title]).to eq('Testing')
      end

      it 'preserves the order of the attributes in the source data' do
        # when
        result = attribute_map.attributes
        # then
        actual_ordered_keys = result.keys
        expected_ordered_keys = source_data.keys
        expected_title_position = expected_ordered_keys.index(:title)
        actual_title_position = actual_ordered_keys.index(:title)
        expect(actual_title_position).to eq(expected_title_position)
        expected_id_position = expected_ordered_keys.index(:external_id)
        actual_id_position = actual_ordered_keys.index(:id)
        expect(actual_id_position).to eq(expected_id_position)
        expected_legacy_id_position = expected_ordered_keys.index(:legacy_id)
        actual_legacy_id_position = actual_ordered_keys.index(:legacy_id)
        expect(actual_legacy_id_position).to eq(expected_legacy_id_position)
      end
    end

    context 'for sort hash (API->Model)' do
      let(:options) { { transformer_type_for_source: AttributeHashTransformer.name, contains_model_attributes: false } }
      let(:source_data) { { legacy_id: blog_post.legacy_id, title: blog_post.title, id: blog_post.external_id } }
      let(:attribute_map) { BlogPostAttributeMap.new(source_data, options) }

      it 'generates model attribute keys (leaving values unchanged)' do
        # when
        result = attribute_map.attributes
        # then
        expect(result[:title]).to eq('Testing')
      end

      it 'preserves the order of the attributes in the source data' do
        # when
        result = attribute_map.attributes
        # then
        actual_ordered_keys = result.keys
        expected_ordered_keys = source_data.keys
        expected_title_position = expected_ordered_keys.index(:title)
        actual_title_position = actual_ordered_keys.index(:title)
        expect(actual_title_position).to eq(expected_title_position)
        expected_id_position = expected_ordered_keys.index(:id)
        actual_id_position = actual_ordered_keys.index(:external_id)
        expect(actual_id_position).to eq(expected_id_position)
        expected_legacy_id_position = expected_ordered_keys.index(:legacy_id)
        actual_legacy_id_position = actual_ordered_keys.index(:legacy_id)
        expect(actual_legacy_id_position).to eq(expected_legacy_id_position)
      end
    end

  end
end
