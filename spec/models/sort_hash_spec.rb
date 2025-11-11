# frozen_string_literal: true

require 'spec_helper'

module PackAPI::Querying
  RSpec.describe SortHash, type: :model do

    describe '#initialize' do
      it 'accepts nil' do
        expect(described_class.new(nil)).to eq({})
      end

      it 'accepts a comma-separated string' do
        expect(described_class.new('name desc, product_medium')).to eq({ name: :desc, product_medium: :asc })
      end

      it 'accepts a string and a sort direction' do
        expect(described_class.new('name asc')).to eq({ name: :asc })
      end

      it 'accepts a string, and assumes a sort direction' do
        expect(described_class.new('name')).to eq({ name: :asc })
      end

      it 'accepts a symbol, and assumes a sort direction' do
        expect(described_class.new(:name)).to eq({ name: :asc })
      end

      it 'accepts a hash' do
        expect(described_class.new({ name: :asc, id: :desc })).to eq({ name: :asc, id: :desc })
      end

      it 'leaves keys unchanged' do
        expect(described_class.new({ 'name' => 'asc' })).to have_key('name')
        expect(described_class.new({ :name => 'asc' })).to have_key(:name)
        expect(described_class.new({ Arel.sql('name') => 'asc' })).to have_key(Arel.sql('name'))
      end

      it 'discards nil keys in a hash' do
        expect(described_class.new({ nil => nil })).to eq({})
      end

      it 'converts sort directions to symbols' do
        expect(described_class.new({ 'name' => 'asc' })).to eq({ 'name' => :asc })
      end

      it 'discards Arel sort directive' do
        # given
        sql = <<-SQL
          CASE canceled
            WHEN FALSE THEN
              CASE
                WHEN CURRENT_DATE < start_date THEN 1 -- Upcoming
                WHEN CURRENT_DATE <= end_date THEN 0 -- Active
                ELSE 2 -- Completed
              END
            ELSE 3 -- Canceled
          END,
          end_date
        SQL

        arel = Arel.sql(sql)

        # when/then
        expect(described_class.new(arel)).to eq({}),
          "Arel sort directive should be discarded from a SortHash, since Arel can't be shown in the front end or manipulated by the user"
      end

      it 'preserves nested (association) sort directives' do
        # when
        sort_hash = described_class.new({ association: { 'name' => 'asc' }})
        # then
        expect(sort_hash).to include(:association)
        expect(sort_hash[:association]).to include('name')
        expect(sort_hash[:association]['name']).to eq(:asc)
      end
    end
  end
end