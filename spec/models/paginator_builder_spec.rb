# frozen_string_literal: true

require 'spec_helper'

module PackAPI::Pagination
  RSpec.describe PaginatorBuilder, type: :model do
    let(:query) { {} }
    let(:offset) { 2 }
    let(:per_page) { 5 }
    let(:sort) { nil }
    let(:total_items) { 10 }

    describe '#set_cursor' do
      let(:cursor) { PaginatorCursor.create(query:, sort:, total_items:, offset:, per_page:) }

      it 'produces a paginator with query attribute set' do
        paginator = described_class.build { |builder| builder.set_cursor(cursor:) }
        expect(paginator.query).to eq({})
      end

      context 'with a sort hash' do
        let(:sort) { { name: :asc } }

        it 'produces a paginator with sort attribute set' do
          paginator = described_class.build { |builder| builder.set_cursor(cursor:) }
          expect(paginator.sort).to eq({ name: 'asc' })
        end
      end

      context 'with a sort string' do
        let(:sort) { 'name asc' }

        it 'produces a paginator with sort attribute set' do
          paginator = described_class.build { |builder| builder.set_cursor(cursor:) }
          expect(paginator.sort).to eq('name asc')
        end
      end

      it 'produces a paginator with total_items attribute set' do
        paginator = described_class.build { |builder| builder.set_cursor(cursor:) }
        expect(paginator.total_items).to eq(10)
      end

      it 'produces a paginator with per_page attribute set' do
        paginator = described_class.build { |builder| builder.set_cursor(cursor:) }
        expect(paginator.per_page).to eq(5)
      end

      it 'produces a paginator with offset attribute set' do
        paginator = described_class.build { |builder| builder.set_cursor(cursor:) }
        expect(paginator.offset).to eq(2)
      end

      context 'with sort override' do
        it 'picks first page of new record set' do
          paginator = described_class.build { |builder| builder.set_cursor(cursor:, sort: 'name desc') }
          expect(paginator.offset).to eq(0)
        end
      end

      context 'with sort specified, but not different than cursor' do
        it 'uses cursor offset' do
          paginator = described_class.build { |builder| builder.set_cursor(cursor:, sort:) }
          expect(paginator.offset).not_to eq(0)
        end
      end
    end

    describe '#set_params' do
      let(:query) { { foo: { bar: :baz } } }
      let(:sort) { { name: :asc } }
      let(:paginator) do
        described_class.build { |builder| builder.set_params(query:, offset:, sort:, per_page:, total_items:) }
      end

      it 'produces a paginator with query attribute set' do
        expect(paginator.query).to eq({ foo: { bar: :baz } })
      end

      it 'produces a paginator with sort attribute set' do
        expect(paginator.sort).to eq({ name: :asc })
      end

      it 'produces a paginator with total_items attribute set' do
        expect(paginator.total_items).to eq(10)
      end

      it 'produces a paginator with per_page attribute set' do
        expect(paginator.per_page).to eq(5)
      end

      it 'produces a paginator with offset attribute set' do
        expect(paginator.offset).to eq(2)
      end

      context 'with per_page = :all' do
        let(:per_page) { :all }

        it 'yields a paginator that will include all results in the collection query' do
          expect(paginator.offset).to eq(0), "offset should be 0 (was #{paginator.offset})"
          expect(paginator.total_items).to eq(10), "total_items should be 10 (was #{paginator.total_items})"
          expect(paginator.per_page).to eq(:all), "per_page should be :all (was #{paginator.per_page})"
          expect(paginator.sort).to eq(sort), "sort should be be #{sort} (was #{paginator.sort})"
        end
      end

      context 'with params already set by cursor' do
        let(:cursor) do
          PaginatorCursor.create(query: { foo: { hello: :world } },
                                 sort: { price: :desc },
                                 total_items: 1000,
                                 offset: 100,
                                 metadata: { foo: :bar },
                                 per_page: 100)
        end

        context 'and new query param' do
          let(:paginator) do
            described_class.build do |builder|
              builder.set_cursor(cursor:)
              builder.set_params(query:)
            end
          end

          it 'merges cursor query with new query' do
            expect(paginator.query[:foo]).to include(:bar)
            expect(paginator.query[:foo]).to include(:hello)
            expect(paginator.query.dig(:foo, :hello)).to eq('world')
          end

          it 'resets the offset to 0' do
            expect(paginator.offset).to eq(0)
          end

          it 'does not overwrite the metadata' do
            expect(paginator.metadata).not_to be_nil
          end
        end

        context 'and new sort param' do
          let(:paginator) do
            described_class.build do |builder|
              builder.set_cursor(cursor:)
              builder.set_params(sort:)
            end
          end

          it 'replaces cursor sort with new sort' do
            expect(paginator.sort).to eq(sort)
          end

          it 'resets the offset to 0' do
            expect(paginator.offset).to eq(0)
          end

          it 'does not overwrite the metadata' do
            expect(paginator.metadata).not_to be_nil
          end
        end

      end
    end
  end
end