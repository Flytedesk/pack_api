# frozen_string_literal: true

module PackAPI
  class ValuesInBackgroundBatches < ValuesInBatches
    include Enumerable

    attr_reader :low_watermark, :background_worker

    def initialize(method:, batch_size:, optional_attributes: nil, **kwargs, &block)
      super
      @low_watermark = 1
    end

    def each
      @background_worker = Rails.env.test? ?
         Concurrent::ImmediateExecutor.new :
         Concurrent::SingleThreadExecutor.new
      super
      background_worker.shutdown
      @background_worker = nil
    end

    private

    def process_item(index, item, block)
      cache_next_batch if index == low_watermark
      block.call(item)
    end

    def cache_key
      @cache_key ||= "api:batches:#{SecureRandom.uuid}"
    end

    def cache_next_batch
      background_worker.post do
        Rails.application.executor.wrap do
          Rails.logger.debug { "Storing next batch in cache #{cache_key}" }
          Rails.cache.write(cache_key, fetch_batch(cursor: next_batch_cursor), expires_in: 1.minute)
        end
      end
    end

    def make_next_batch_available
      cached_next_result = Rails.cache.read(cache_key)
      if cached_next_result.nil?
        Rails.logger.debug { "Fetching next batch without cache #{cache_key}" }
        @result = fetch_batch(cursor: next_batch_cursor)
      else
        Rails.logger.debug { "Fetching next batch from cache #{cache_key}" }
        @result = cached_next_result
      end

      raise PackAPI::InternalError.new(object: @result.errors) unless @result.success
    ensure
      Rails.cache.delete(cache_key)
    end
  end
end
