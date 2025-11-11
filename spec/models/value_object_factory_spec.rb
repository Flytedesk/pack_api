# frozen_string_literal: true

require 'spec_helper'

module PackAPI::Mapping
  RSpec.describe ValueObjectFactory, type: :model do
    let!(:author) { Author.create(name: 'Alex', external_id: '9') }
    let!(:blog_post) { BlogPost.create(title: 'Testing', external_id: '1', legacy_id: '2', earnings: 10.0, author:) }
    let!(:comment_one) { blog_post.comments.create(txt: 'Comment1', blog_post:) }
    let!(:comment_two) { blog_post.comments.create(txt: 'Comment2', blog_post:) }

    let(:factory) { TestValueObjectFactory.new }

    describe '#create_object' do
      it 'can create a value object from a model' do
        value_object = factory.create_object(model: blog_post)
        expect(value_object).to be_a(BlogPostType)
      end

      it 'can create associated value objects based on optional_attributes' do
        value_object = factory.create_object(model: blog_post, optional_attributes: [:associated])
        expect(value_object.associated).not_to be_nil
      end

      it 'can omit associated value objects based on optional_attributes' do
        value_object = factory.create_object(model: blog_post, optional_attributes: nil)
        expect(value_object.associated).to be_nil
      end
    end

    describe '#create_collection' do
      it 'can create associated value object collections based on optional_attributes' do
        value_object = factory.create_object(model: blog_post, optional_attributes: [:notes])
        expect(value_object.notes).not_to be_nil
        expect(value_object.notes).to have(2).items
      end
    end

    describe '#create_errors' do
      it 'can create attribute hash from errors' do
        blog_post.errors.add(:title, 'is required')
        errors = factory.create_errors(model: blog_post)
        expect(errors).to include(:title)
      end
    end
  end
end
