# frozen_string_literal: true

require 'spec_helper'

module PackAPI::Pagination
  RSpec.describe PaginatorCursor, type: :model do
    let(:sort_expression) { 'bar' }
    let(:query) { 'foo' }
    let(:cursor) do
      described_class.create(query:,
                             sort: sort_expression,
                             total_items: 1,
                             offset: 2,
                             per_page: 3)
    end

    describe '.parse' do

      it 'preserves query through serialization and deserialization' do
        # when
        cursor_params = described_class.parse(cursor)
        # then
        expect(cursor_params).to include(query: 'foo')
      end

      it 'preserves sort through serialization and deserialization' do
        # when
        cursor_params = described_class.parse(cursor)
        # then
        expect(cursor_params).to include(sort: 'bar')
      end

      it 'preserves total_items through serialization and deserialization' do
        # when
        cursor_params = described_class.parse(cursor)
        # then
        expect(cursor_params).to include(total_items: 1)
      end

      it 'preserves offset through serialization and deserialization' do
        # when
        cursor_params = described_class.parse(cursor)
        # then
        expect(cursor_params).to include(offset: 2)
      end

      it 'preserves per_page through serialization and deserialization' do
        # when
        cursor_params = described_class.parse(cursor)
        # then
        expect(cursor_params).to include(per_page: 3)
      end

      context 'when sort is Arel::Nodes::SqlLiteral' do
        let(:sort_expression) { Arel.sql('name asc') }

        it 'preserves sort through serialization and deserialization' do
          # when
          cursor_params = described_class.parse(cursor)
          # then
          expect(cursor_params).to include(:sort)
          expect(cursor_params[:sort]).to be_a(Arel::Nodes::SqlLiteral)
        end
      end

      context 'when sort is a Hash containing Arel::Nodes::SqlLiteral' do
        let(:sort_expression) { { Arel.sql('name') => 'asc' } }

        it 'preserves sort through serialization and deserialization' do
          # when
          cursor_params = described_class.parse(cursor)
          # then
          expect(cursor_params).to include(:sort)
          expect(cursor_params[:sort]).to be_a(Hash)
          expect(cursor_params[:sort].keys.first).to be_a(Arel::Nodes::SqlLiteral)
          expect(cursor_params[:sort].values.first).to eq('asc')
        end
      end

      context 'with very large queries' do
        let(:ids) { Array.new(200) { SecureRandom.uuid } }
        let(:query) { { filters: { id: ids } } }

        it 'has at most 2048 characters' do
          expect(cursor.length).to be <= PaginatorCursor::MAX_LENGTH
        end

        it 'can be parsed' do
          # when
          cursor_params = described_class.parse(cursor)
          # then
          expect(cursor_params).to include(:query)
          expect(cursor_params[:query]).to include(:filters)
          expect(cursor_params[:query][:filters]).to include(:id)
          expect(cursor_params[:query][:filters][:id]).to have(200).items
        end
      end

      context 'when encoded cursor cannot be Base64-decoded' do
        let(:cursor) { 'foo' }

        it 'raises PackAPI::InternalError' do
          expect { described_class.parse(cursor) }.to raise_error(PackAPI::InternalError)
        end
      end

      context 'when Base64-decoded cursor cannot be Brotli-inflated' do
        let(:cursor) { Base64.strict_encode64('foo') }

        it 'raises PackAPI::InternalError' do
          expect { described_class.parse(cursor) }.to raise_error(PackAPI::InternalError)
        end
      end

      context 'when Base64-decoded, Brotli-inflated cursor cannot be JSON-parsed' do
        let(:cursor) { Base64.strict_encode64(Brotli.deflate('foo')) }

        it 'raises PackAPI::InternalError' do
          expect { described_class.parse(cursor) }.to raise_error(PackAPI::InternalError)
        end
      end

      context 'when Base64-decoded, Brotli-inflated, JSON-parsed cursor is a string and cannot be cache-decoded' do
        let(:cursor) { Base64.strict_encode64(Brotli.deflate('foo'.to_json)) }

        it 'raises PackAPI::InternalError' do
          expect { described_class.parse(cursor) }.to raise_error(PackAPI::InternalError)
        end
      end

      context 'when Base64-decoded, Brotli-inflated, JSON-parsed cursor is not a string or hash' do
        let(:cursor) { Base64.strict_encode64(Brotli.deflate(0.to_json)) }

        it 'raises PackAPI::InternalError' do
          expect { described_class.parse(cursor) }.to raise_error(PackAPI::InternalError)
        end
      end

      context 'when decoded[:sort][:sql_literal] is not a hash' do
        let(:cursor) { Base64.strict_encode64(Brotli.deflate({ sort: { sql_literal: 'foo' } }.to_json)) }

        it 'raises PackAPI::InternalError' do
          expect { described_class.parse(cursor) }.to raise_error(PackAPI::InternalError)
        end
      end

      context 'when decoded[:sort][:sql_literal] does not include :raw_sql' do
        let(:cursor) { Base64.strict_encode64(Brotli.deflate({ sort: { sql_literal: {} } }.to_json)) }

        it 'raises PackAPI::InternalError' do
          expect { described_class.parse(cursor) }.to raise_error(PackAPI::InternalError)
        end
      end

      context 'when decoded[:sort][:sql_literal_<n>] is not a hash' do
        let(:cursor) { Base64.strict_encode64(Brotli.deflate({ sort: { sql_literal_1: 'foo' } }.to_json)) }

        it 'raises PackAPI::InternalError' do
          expect { described_class.parse(cursor) }.to raise_error(PackAPI::InternalError)
        end
      end

      context 'when decoded[:sort][:sql_literal_<n>] does not include :raw_sql' do
        let(:cursor) { Base64.strict_encode64(Brotli.deflate({ sort: { sql_literal_1: {} } }.to_json)) }

        it 'raises PackAPI::InternalError' do
          expect { described_class.parse(cursor) }.to raise_error(PackAPI::InternalError)
        end
      end

      context 'when decoded[:sort][:sql_literal_<n>][:raw_sql] is not a string' do
        let(:cursor) do
          Base64.strict_encode64(Brotli.deflate({ sort: { sql_literal_1: { raw_sql: 0 } } }.to_json))
        end

        it 'raises PackAPI::InternalError' do
          expect { described_class.parse(cursor) }.to raise_error(PackAPI::InternalError)
        end
      end
    end
  end
end
