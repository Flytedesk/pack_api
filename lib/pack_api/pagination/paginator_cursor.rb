# frozen_string_literal: true

module PackAPI::Pagination
  class PaginatorCursor
    MAX_LENGTH = 2048
    CACHE_KEY_PREFIX = 'paginator_cursor'
    CACHE_EXPIRES_IN = 8.hours

    class << self
      def create(query:, sort:, total_items:, offset:, per_page:, metadata: nil)
        sort_ready_to_serialize = SqlLiteralSerializer.serialize(sort)
        cursor_params = { query:, sort: sort_ready_to_serialize, total_items:, offset:, per_page:, metadata: }
        token = OpaqueTokenV2.create(cursor_params)
        return token if token.size <= MAX_LENGTH

        cache_key = generate_cache_key
        Rails.cache.write(cache_key, cursor_params, expires_in: CACHE_EXPIRES_IN)
        OpaqueTokenV2.create(cache_key)
      end

      def parse(encoded)
        decoded = parse_opaque_token(encoded)
        decoded = decode_cache_key(decoded) if decoded.is_a?(String)
        decoded[:sort] = deserialize_sort_args(decoded)
        decoded
      end

      private

      def parse_opaque_token(encoded)
        OpaqueTokenV2.parse(encoded)
      rescue ArgumentError, Brotli::Error, JSON::ParserError => e
        raise_error(e.message)
      end

      def raise_error(message)
        raise(PackAPI::InternalError, "un-parsable paginator cursor: #{message}")
      end

      def decode_cache_key(cache_key)
        data = Rails.cache.read(cache_key)
        raise(PackAPI::InternalError, "no data found in cache for key #{cache_key}") if data.nil?

        data
      end

      def generate_cache_key
        "#{CACHE_KEY_PREFIX}:#{SecureRandom.uuid}"
      end

      def deserialize_sort_args(cursor)
        SqlLiteralSerializer.deserialize(cursor[:sort])
      rescue TypeError => e
        raise_error(e.message)
      end

      # in order to recognize Arel::Nodes::SqlLiteral during parsing,
      # we need to serialize it differently than a string
      class SqlLiteralSerializer
        def self.serialize(args)
          return { sql_literal: { raw_sql: args.to_s } } if args.is_a?(Arel::Nodes::SqlLiteral)
          return args unless args.is_a?(Hash)

          args.map.with_index do |entry, index|
            next entry unless entry[0].is_a?(Arel::Nodes::SqlLiteral)

            ["sql_literal_#{index + 1}", { raw_sql: entry[0].to_s, hash_value: entry[1] }]
          end.to_h
        end

        def self.deserialize(args)
          return args unless args.is_a?(Hash)
          return Arel.sql(args[:sql_literal][:raw_sql]) if args.key?(:sql_literal)

          args.to_h do |key, value|
            next [key, value] unless key.start_with?('sql_literal_')

            [Arel.sql(value[:raw_sql]), value[:hash_value]]
          end
        end
      end
    end


  end
end
