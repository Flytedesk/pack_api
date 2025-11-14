# frozen_string_literal: true

require 'spec_helper'

module PackAPI::Querying
  RSpec.describe CollectionQuery, type: :model do
    let(:query) do
      query = described_class.new(collection: BlogPost.all)
      query.filter_factory = Filters::BlogPost::FilterFactory.new
      query
    end

    describe '#call' do
      let!(:record_one) do
        BlogPost.create!(id: 1,
                         earnings: 1,
                         title: 'test1',
                         drafted_on: Date.current,
                         published_on: Date.current + 2.days)
      end

      let!(:record_two) do
        BlogPost.create!(id: 2,
                         earnings: 2,
                         title: 'test2',
                         drafted_on: Date.current + 1.day,
                         published_on: Date.current + 3.days)
      end

      context 'with default filters' do
        it 'supports hash conditions' do
          # when
          query.call(filters: { title: 'test2' })
          # then
          expect(query.results.count).to eq(1)
        end

        it 'supports array conditions' do
          # when
          query.call(filters: ['title = ?', 'test2'])
          # then
          expect(query.results.count).to eq(1)
        end

        it 'supports string conditions' do
          # when
          query.call(filters: "title = 'test2'")
          # then
          expect(query.results.count).to eq(1)
        end
      end

      context 'with custom filters' do
        it 'supports complex conditions given a hash input' do
          # given
          record_one.create_author!(name: 'Foo')
          record_one.save!
          # when
          query.call(filters: { author: { value: 'Foo' }})
          # then
          expect(query.results.count).to eq(1)
          expect(query.results.first.title).to eq('test1')
        end

        it 'detects invalid filters' do
          # when
          expect { query.call(filters: { invalid: { value: '123' } }) } .to raise_error(PackAPI::InternalError)
        end
      end

      context 'with searching' do
        it 'limits results to those matching the search terms' do
          # when
          query.call(search: { title: '2' })
          # then
          expect(query.results.count).to eq(1)
        end
      end

      context 'with sorting' do
        it 'works with sort strings' do
          # when
          query.call(sort: 'drafted_on DESC')
          # then
          expect(query.results.first.title).to eq('test2')
          expect(query.results.second.title).to eq('test1')
        end

        it 'works with sort symbols' do
          # when
          query.call(sort: :drafted_on) # assumes ASC
          # then
          expect(query.results.first.title).to eq('test1')
          expect(query.results.second.title).to eq('test2')
        end

        it 'works with sort hashes' do
          # when
          query.call(sort: { drafted_on: :desc })
          # then
          expect(query.results.first.title).to eq('test2')
          expect(query.results.second.title).to eq('test1')
        end

        it 'works with sort Arel' do
          # when
          query.call(sort: Arel.sql('drafted_on DESC'))
          # then
          expect(query.results.first.title).to eq('test2')
          expect(query.results.second.title).to eq('test1')
        end

        context 'with default_sort' do
          let(:query) { described_class.new(collection: BlogPost.all, default_sort: 'drafted_on desc') }

          it 'uses the default sort if query-specific sort is not provided' do
            # when
            query.call
            # then
            expect(query.results.first.title).to eq('test2')
            expect(query.results.second.title).to eq('test1')
          end

          it 'overrides the default sort if query-specific sort is provided' do
            # when
            query.call(sort: 'drafted_on DESC')
            # then
            expect(query.results.second.title).to eq('test1')
            expect(query.results.first.title).to eq('test2')
          end
        end

        it 'ensures a stable sort order' do
          # when
          query.call(sort: { drafted_on: :desc })
          # then
          expect(query.paginator.sort).to have_key(:id)
        end
      end

      context 'with pagination' do
        it 'can limit results to a single page' do
          # when
          query.call(per_page: 1)
          # then
          expect(query.results.count).to eq(1)
          expect(query.paginator.next_page_cursor).not_to be_nil
        end

        it 'can continue a previous query' do
          # given
          query.call(per_page: 1)
          paginator = query.paginator
          query.reset
          # when
          query.call(cursor: paginator.next_page_cursor)
          # then
          expect(query.results.count).to eq(1)
          expect(query.paginator.next_page_cursor).to be_nil
        end

        it 'preserves the custom sort to subsequent pages' do
          # given
          query.call(per_page: 1, sort: 'title DESC')
          paginator = query.paginator
          query.reset
          # when
          query.call(cursor: paginator.next_page_cursor)
          # then
          expect(query.results.first.id).to eq(record_one.id)
        end

        it 'resets to page 1 when a NEW sort is given' do
          # given
          query.call(per_page: 1, sort: 'title DESC')
          paginator = query.paginator
          query.reset
          # when
          query.call(cursor: paginator.next_page_cursor, sort: 'title ASC')
          # then
          expect(query.paginator.item_range).to eq(1..1)
        end

        it 'preserves the custom sort to subsequent pages when the sort is specified, but is not different' do
          # given
          query.call(per_page: 1, sort: 'title DESC')
          paginator = query.paginator
          query.reset
          # when
          query.call(cursor: paginator.next_page_cursor, sort: 'title DESC')
          # then
          expect(query.paginator.item_range).to eq(2..2)
        end

        it 'returns no records when cursor points to records that have been removed from the recordset' do
          # given
          query.call(per_page: 1)
          paginator = query.paginator
          query.reset
          record_two.destroy!
          # when
          query.call(cursor: paginator.next_page_cursor)
          # then
          expect(query.results.count).to eq(0)
        end
      end

      context 'with current_page_snapshot_cursor' do
        let(:filters) { { earnings: [1, 2, 3] } }
        let(:sort) { 'drafted_on DESC' } # expect records in order: 3, 2, 1
        let!(:record_three) do
          BlogPost.create!(id: 3,
                           earnings: 3,
                           title: 'test3',
                           drafted_on: Date.current + 2.days,
                           published_on: Date.current + 4.days)
        end
        let!(:current_page_snapshot_cursor) do
          query.call(filters:, sort:)
          query.current_page_snapshot_cursor
        end

        before :each do
          # move record three out of position #1 in the sorted recordset
          record_three.update(drafted_on: Date.current - 1.day)
          # remove record one from the recordset (based on filters)
          record_one.update(earnings: 100)
          # add record four to the start of the sorted recordset
          BlogPost.create!(id: 4,
                           earnings: 1,
                           title: 'test4',
                           drafted_on: Date.current + 3.days,
                           published_on: Date.current + 5.days)
          query.reset
        end

        it 'yields the targeted record' do
          # when
          query.call(cursor: current_page_snapshot_cursor, filters: { id: record_two.id })
          # then
          expect(query.results.count).to eq(1), "Only one record should be returned (got #{query.results.count})"
          expect(query.paginator.per_page).to eq(1), "Paginator should be configured to provide access to one record (got #{query.paginator.per_page})"
          expect(query.paginator.total_items).to eq(3), "Resultset size should be fixed to what the recordset was like when the cursor was generated (now includes #{query.paginator.total_items} records)"
          expect(query.results.first.id).to eq(record_two.id), "Expected to find record one, but found record #{query.results.first.id}"
        end

        it 'yields the targeted record even when it is not a part of the recordset' do
          # when
          query.call(cursor: current_page_snapshot_cursor, filters: { id: record_one.id })
          # then
          expect(query.results.count).to eq(1), "Only one record should be returned (got #{query.results.count})"
          expect(query.paginator.per_page).to eq(1), "Paginator should be configured to provide access to one record (got #{query.paginator.per_page})"
          expect(query.paginator.total_items).to eq(3), "Resultset size should be fixed to what the recordset was like when the cursor was generated (now includes #{query.paginator.total_items} records)"
          expect(query.results.first.id).to eq(record_one.id), "Expected to find record one, but found record #{query.results.first.id}"
        end

        it 'can iterate across records in the original resultset' do
          # when
          query.call(cursor: current_page_snapshot_cursor, filters: { id: record_two.id })
          # then
          expect(query.paginator.previous_page_cursor).not_to be_nil
          record_three_cursor = query.paginator.previous_page_cursor
          expect(query.paginator.next_page_cursor).not_to be_nil
          record_one_cursor = query.paginator.next_page_cursor
          query.reset
          # verify we can proceed to record one
          query.call(cursor: record_one_cursor)
          expect(query.results.count).to eq(1), "Only one record should be returned (got #{query.results.count})"
          expect(query.paginator.per_page).to eq(1), "Paginator should be configured to provide access to one record (got #{query.paginator.per_page})"
          expect(query.paginator.total_items).to eq(3), "Resultset size should be fixed to what the recordset was like when the cursor was generated (now includes #{query.paginator.total_items} records)"
          expect(query.results.first.id).to eq(record_one.id), "Expected to find record 1, but found record #{query.results.first.id}"
          expect(query.paginator.next_page_cursor).to be_nil, 'Record 1 should be at the end of the resultset, and should not have a next page'
          expect(query.paginator.previous_page_cursor).not_to be_nil, 'Record 1 should be at the end of the resultset, and should have a previous page'
          query.reset
          # verify we can proceed to record three
          query.call(cursor: record_three_cursor)
          expect(query.results.count).to eq(1), "Only one record should be returned (got #{query.results.count})"
          expect(query.paginator.per_page).to eq(1), "Paginator should be configured to provide access to one record (got #{query.paginator.per_page})"
          expect(query.paginator.total_items).to eq(3), "Resultset size should be fixed to what the recordset was like when the cursor was generated (now includes #{query.paginator.total_items} records)"
          expect(query.results.first.id).to eq(record_three.id), "Expected to find record 3, but found record #{query.results.first.id}"
          expect(query.paginator.next_page_cursor).not_to be_nil, 'Record 3 should be at the start of the resultset, and should have a next page'
          expect(query.paginator.previous_page_cursor).to be_nil, 'Record 3 should be at the start of the resultset, and should not have a previous page'
        end

        context 'and record with record_id does not exist' do
          it 'yields no results' do
            # given
            record_two.destroy!
            # when
            query.call(cursor: current_page_snapshot_cursor, filters: { id: record_two.id })
            # then
            expect(query.results).to be_empty
          end
        end

        context 'and a record in the snapshot is deleted prior to focusing on to a single record' do
          before :each do
            record_three.destroy!
          end

          it 'yields the targeted record' do
            # when
            query.call(cursor: current_page_snapshot_cursor, filters: { id: record_two.id })
            # then
            expect(query.results.count).to eq(1), "Only one record should be returned (got #{query.results.count})"
            expect(query.paginator.per_page).to eq(1), "Paginator should be configured to provide access to one record (got #{query.paginator.per_page})"
            expect(query.results.first.id).to eq(record_two.id), "Expected to find record 2, but found record #{query.results.first.id}"
          end

          it 'updates the total_items count' do
            # when
            query.call(cursor: current_page_snapshot_cursor, filters: { id: record_two.id })
            # then
            expect(query.paginator.total_items).to eq(2), "Resultset size should omit the deleted record"
          end

          it 'omits the deleted record in adjacent cursors' do
            # when
            query.call(cursor: current_page_snapshot_cursor, filters: { id: record_one.id })
            # then
            expect(query.paginator.previous_page_cursor).not_to be_nil
            record_two_cursor = query.paginator.previous_page_cursor
            query.reset
            query.call(cursor: record_two_cursor)
            expect(query.results.count).to eq(1), "Only one record should be returned (got #{query.results.count})"
            expect(query.paginator.per_page).to eq(1), "Paginator should be configured to provide access to one record (got #{query.paginator.per_page})"
            expect(query.paginator.total_items).to eq(2), "Resultset size should omit the deleted record"
            expect(query.results.first.id).to eq(record_two.id), "Expected to find record 2, but found record #{query.results.first.id}"
            expect(query.paginator.previous_page_cursor).to be_nil, 'Record 2 should be at the start of the resultset, and should not have a previous page'
            expect(query.paginator.next_page_cursor).not_to be_nil, 'Record 2 should be at the start of the resultset, and should have a next page'
            record_one_cursor = query.paginator.next_page_cursor
            query.reset
            query.call(cursor: record_one_cursor)
            expect(query.results.count).to eq(1), "Only one record should be returned (got #{query.results.count})"
            expect(query.paginator.per_page).to eq(1), "Paginator should be configured to provide access to one record (got #{query.paginator.per_page})"
            expect(query.paginator.total_items).to eq(2), "Resultset size should omit the deleted record"
            expect(query.results.first.id).to eq(record_one.id), "Expected to find record 1, but found record #{query.results.first.id}"
            expect(query.paginator.next_page_cursor).to be_nil, 'Record 1 should be at the end of the resultset, and should not have a next page'
            expect(query.paginator.previous_page_cursor).not_to be_nil, 'Record 1 should be at the end of the resultset, and should have a previous page'
          end
        end

        context 'and a record in the snapshot is deleted while traversing the snapshot records' do
          it 'skips the deleted record' do
            # given
            query.call(cursor: current_page_snapshot_cursor, filters: { id: record_two.id })
            expect(query.paginator.next_page_cursor).not_to be_nil
            next_page_cursor = query.paginator.next_page_cursor
            query.reset
            record_three.destroy!
            # when
            query.call(cursor: next_page_cursor)
            # then
            expect(query.results.count).to eq(1), "Only one record should be returned (got #{query.results.count})"
            expect(query.results.first.id).to eq(record_one.id), "Expected to find record 1, but found record #{query.results.first.id}"
          end

          it 'updates the metadata' do
            # given
            query.call(cursor: current_page_snapshot_cursor, filters: { id: record_two.id })
            expect(query.paginator.next_page_cursor).not_to be_nil
            next_page_cursor = query.paginator.next_page_cursor
            query.reset
            record_three.destroy!
            # when
            query.call(cursor: next_page_cursor)
            # then
            expect(query.paginator.per_page).to eq(1), "Paginator should be configured to provide access to one record (got #{query.paginator.per_page})"
            expect(query.paginator.total_items).to eq(2), "Resultset size should omit the deleted record"
          end
        end
      end

      context 'with pagination cursor and search' do
        it 'overrides the search used in the cursor query' do
          # given
          query.call(per_page: 1, search: { title: '2' })
          paginator = query.paginator
          query.reset
          # when
          query.call(cursor: paginator.current_page_cursor, search: { title: 'test' })
          # then
          expect(query.paginator.total_items).to eq(2)
        end
      end
    end
  end
end
