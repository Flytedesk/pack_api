# frozen_string_literal: true

require 'brotli'

module PackAPI::Pagination
  class OpaqueTokenV2
    def self.create(unencoded)
      Base64.strict_encode64(Brotli.deflate(unencoded.to_json))
    end

    def self.parse(encoded)
      raise JSON::ParserError if encoded.nil?

      decoded = Base64.strict_decode64(encoded)
      decompressed = Brotli.inflate(decoded)
      JSON.parse(decompressed, symbolize_names: true)
    end
  end
end
