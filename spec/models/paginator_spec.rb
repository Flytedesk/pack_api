# frozen_string_literal: true

require 'spec_helper'

module PackAPI::Pagination
  RSpec.describe Paginator, type: :model do
    let(:offset) { 2 }
    let(:per_page) { 2 }
    let(:total_items) { 10 }
    let(:paginator) do
      PaginatorBuilder.build do |builder|
        builder.set_params(offset:, sort: 'name asc', per_page:, total_items:)
      end
    end

    describe '#item_range' do
      it 'reflects the first and last record number in the current results' do
        expect(paginator.item_range).to eq(3..4)
      end

      context 'when total_items < per_page' do
        let(:offset) { 0 }
        let(:per_page) { 20 }
        let(:total_items) { 4 }

        it 'does not exceed #total_items' do
          expect(paginator.item_range).to eq(1..4)
        end
      end

      context 'when per_page = :all' do
        let(:offset) { 2 }
        let(:per_page) { :all }
        let(:total_items) { 4 }

        it 'has a lower bound = 1' do
          expect(paginator.item_range.begin).to eq(1)
        end

        it 'has an upper bound of total_items' do
          expect(paginator.item_range.end).to eq(total_items)
        end
      end

      context 'when per_page = 0' do
        let(:offset) { 0 }
        let(:per_page) { 0 }
        let(:total_items) { 4 }

        it 'is 0..0' do
          expect(paginator.item_range).not_to be_nil
          expect(paginator.item_range.begin).to eq(0)
          expect(paginator.item_range.end).to eq(0)
        end
      end
    end

    describe '#offset' do
      context 'when per_page.positive?' do
        let(:offset) { 0 }
        let(:per_page) { 1 }

        it 'is the input value' do
          expect(paginator.offset).to eq(offset)
        end
      end

      context 'when per_page = :all' do
        let(:offset) { 2 }
        let(:per_page) { :all }

        it 'is 0' do
          expect(paginator.offset).to eq(0)
        end
      end

      context 'when per_page.zero?' do
        let(:offset) { 2 }
        let(:per_page) { 0 }

        it 'is the input value' do
          expect(paginator.offset).to eq(offset)
        end
      end
    end

    describe '#limit' do
      context 'when per_page.positive?' do
        let(:per_page) { 2 }

        it 'is the page size' do
          expect(paginator.limit).to eq(2)
        end
      end

      context 'when per_page = :all' do
        let(:per_page) { :all }

        it 'is nil' do
          expect(paginator.limit).to be_nil
        end
      end

      context 'when per_page.zero?' do
        let(:per_page) { 0 }

        it 'is 0' do
          expect(paginator.limit).to be_zero
        end
      end
    end

    describe '#current_page_cursor' do
      it 'can be used to retrieve the current page of records in the recordset' do
        # when
        cursor = paginator.current_page_cursor
        # then
        current_page = PaginatorBuilder.build { |builder| builder.set_cursor(cursor:) }
        expect(current_page.item_range).to eq(paginator.item_range)
      end

      context 'when per_page = :all' do
        let(:offset) { 0 }
        let(:per_page) { :all }

        it 'is not nil' do
          expect(paginator.current_page_cursor).not_to be_nil
        end
      end

      context 'when per_page = 0' do
        let(:offset) { 0 }
        let(:per_page) { 0 }

        it 'is nil' do
          # when
          cursor = paginator.current_page_cursor
          # then
          expect(cursor).to be_nil
        end
      end
    end

    describe '#next_page_cursor' do
      context 'when not at last page' do
        it 'can be used to retrieve the next page of records in the recordset' do
          # when
          cursor = paginator.next_page_cursor
          # then
          next_page = PaginatorBuilder.build { |builder| builder.set_cursor(cursor:) }
          expect(next_page.item_range.begin).to eq(paginator.item_range.end + 1)
        end
      end

      context 'when at last page' do
        let(:offset) { 8 }

        it 'is nil' do
          expect(paginator.next_page_cursor).to be_nil
        end
      end

      context 'when per_page = :all' do
        let(:offset) { 0 }
        let(:per_page) { :all }

        it 'is nil' do
          expect(paginator.next_page_cursor).to be_nil
        end
      end

      context 'when per_page = 0' do
        let(:offset) { 0 }
        let(:per_page) { 0 }

        it 'is nil' do
          # when
          cursor = paginator.next_page_cursor
          # then
          expect(cursor).to be_nil
        end
      end
    end

    describe '#previous_page_cursor' do
      context 'when not at first page' do
        it 'can be used to retrieve the previous page of records in the recordset' do
          # when
          cursor = paginator.previous_page_cursor
          # then
          previous_page = PaginatorBuilder.build { |builder| builder.set_cursor(cursor:) }
          expect(previous_page.item_range.end).to eq(paginator.item_range.begin - 1)
        end
      end

      context 'when at first page' do
        let(:offset) { 0 }

        it 'is nil' do
          expect(paginator.previous_page_cursor).to be_nil
        end
      end

      context 'when per_page = :all' do
        let(:offset) { 0 }
        let(:per_page) { :all }

        it 'is nil' do
          expect(paginator.previous_page_cursor).to be_nil
        end
      end

      context 'when per_page = 0' do
        let(:offset) { 0 }
        let(:per_page) { 0 }

        it 'is nil' do
          # when
          cursor = paginator.previous_page_cursor
          # then
          expect(cursor).to be_nil
        end
      end
    end

    describe '#first_page_cursor' do
      context 'when not at first page' do
        it 'can be used to retrieve the first page of records in the recordset' do
          # when
          cursor = paginator.first_page_cursor
          # then
          first_page = PaginatorBuilder.build { |builder| builder.set_cursor(cursor:) }
          expect(first_page.item_range.begin).to eq(1)
        end
      end

      context 'when at first page' do
        let(:offset) { 0 }

        it 'is nil' do
          expect(paginator.first_page_cursor).to be_nil
        end
      end

      context 'when per_page = :all' do
        let(:offset) { 0 }
        let(:per_page) { :all }

        it 'is nil' do
          expect(paginator.first_page_cursor).to be_nil
        end
      end

      context 'when per_page = 0' do
        let(:offset) { 0 }
        let(:per_page) { 0 }

        it 'is nil' do
          # when
          cursor = paginator.first_page_cursor
          # then
          expect(cursor).to be_nil
        end
      end
    end

    describe '#last_page_cursor' do
      let(:total_items) { 34 }
      let(:per_page) { 20 }

      context 'when not at last page' do
        it 'can be used to retrieve the last page of records in the recordset' do
          # when
          cursor = paginator.last_page_cursor
          # then
          last_page = PaginatorBuilder.build { |builder| builder.set_cursor(cursor:) }
          expect(last_page.item_range.begin).to eq(21)
          expect(last_page.item_range.end).to eq(34)
        end

        context 'when items are integer multiple of per_page' do
          let(:total_items) { 40 }
          let(:per_page) { 20 }

          it 'retrieves the correct range of the last page' do
            # when
            cursor = paginator.last_page_cursor
            # then
            last_page = PaginatorBuilder.build { |builder| builder.set_cursor(cursor:) }
            expect(last_page.item_range.begin).to eq(21)
            expect(last_page.item_range.end).to eq(40)
          end
        end
      end

      context 'when at last page' do
        let(:offset) { 20 }

        it 'is nil' do
          expect(paginator.last_page_cursor).to be_nil
        end
      end

      context 'when per_page = :all' do
        let(:offset) { 0 }
        let(:per_page) { :all }

        it 'is nil' do
          expect(paginator.last_page_cursor).to be_nil
        end
      end

      context 'when per_page = 0' do
        let(:offset) { 0 }
        let(:per_page) { 0 }

        it 'is nil' do
          # when
          cursor = paginator.last_page_cursor
          # then
          expect(cursor).to be_nil
        end
      end
    end

    describe '#recordset_cursor' do
      it 'can be used to retrieve all records in the recordset' do
        # when
        cursor = paginator.recordset_cursor
        # then
        current_page = PaginatorBuilder.build { |builder| builder.set_cursor(cursor:) }
        expect(current_page.offset).to eq(0)
        expect(current_page.per_page).to eq(:all)
      end

      context 'when per_page = 0' do
        let(:offset) { 0 }
        let(:per_page) { 0 }

        it 'is not nil' do
          # when
          cursor = paginator.recordset_cursor
          # then
          expect(cursor).not_to be_nil
        end
      end
    end
  end
end