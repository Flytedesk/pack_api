# frozen_string_literal: true

require 'brotli'

module PackAPI::Pagination
  class OpaqueTokenV2
    # brotli's default quality (11) is tuned for large static assets; cursor payloads are a few hundred bytes of
    # JSON, where quality 5 yields the same size for a fraction of the CPU. Inflate does not depend on quality.
    QUALITY = 5

    def self.create(unencoded)
      Base64.strict_encode64(Brotli.deflate(unencoded.to_json, quality: QUALITY))
    end

    def self.parse(encoded)
      raise JSON::ParserError if encoded.nil?

      decoded = Base64.strict_decode64(encoded)
      decompressed = Brotli.inflate(decoded)
      JSON.parse(decompressed, symbolize_names: true)
    end
  end
end
