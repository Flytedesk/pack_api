# frozen_string_literal: true

require 'spec_helper'

module PackAPI::Mapping
  RSpec.describe PackAPI::Querying::ComposableQuery, type: :model do
    describe '#add' do
      let!(:foo) { BlogPost.create!(title: 'foo') }
      let!(:bar) { BlogPost.create!(title: 'bar') }

      let(:query) { described_class.new(BlogPost.all) }

      it 'can add where clauses' do
        # when
        query.add(BlogPost.where(title: 'foo'))

        # then
        result = query.build.to_a
        expect(result).to have(1).item
        expect(result.first.title).to eq('foo')
      end

      it 'can add join clauses and dependent where clauses' do
        # given
        baz = Author.create!(name: 'baz')
        foo.update(author_id: baz.id)
        # when
        query.add(BlogPost.joins("JOIN authors on authors.id = blog_posts.author_id")
                          .where("authors.name = 'baz'"))
        # then
        result = query.build.to_a
        expect(result).to have(1).item
        expect(result.first.title).to eq('foo')
      end

      it 'can add projections to result' do
        # when
        query.add(BlogPost.select('id baz'))

        # then
        result = query.build.to_a
        expect(result).to have(2).items
        result_baz = result.pluck(:baz)
        expect(result_baz).not_to be_nil
      end
    end
  end
end
