# frozen_string_literal: true

require 'spec_helper'

module PackAPI::Pagination
  RSpec.describe OpaqueTokenV2, type: :model do
    let(:payload) { { query: { seller_id: '42' }, offset: 25, per_page: 25 } }

    it 'round-trips a payload' do
      # when
      parsed = described_class.parse(described_class.create(payload))
      # then
      expect(parsed).to eq(payload)
    end

    # level 11 is brotli's default and costs 40-180x the CPU of level 5 for cursor-sized payloads,
    # for a difference of a few bytes
    it 'compresses at brotli quality 5' do
      # given
      allow(Brotli).to receive(:deflate).and_call_original
      # when
      described_class.create(payload)
      # then
      expect(Brotli).to have_received(:deflate).with(payload.to_json, quality: 5)
    end

    it 'parses tokens compressed at the default quality by earlier versions' do
      # given
      legacy_token = Base64.strict_encode64(Brotli.deflate(payload.to_json))
      # when/then
      expect(described_class.parse(legacy_token)).to eq(payload)
    end
  end
end
