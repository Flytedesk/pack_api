# frozen_string_literal: true

module PackAPI
  class ValuesInBatches
    include Enumerable

    attr_reader :method, :batch_size, :optional_attributes, :kwargs

    def initialize(method:, batch_size:, optional_attributes: nil, **kwargs)
      @method = method
      @batch_size = batch_size
      @optional_attributes = optional_attributes
      @kwargs = kwargs
    end

    def each(&block)
      make_next_batch_available
      return if batch.empty?

      loop do
        batch.each_with_index { |item, index| process_item(index, item, block) }
        break if next_batch_cursor.blank?

        make_next_batch_available
      end
    end

    def batch
      @result.value
    end

    private

    def process_item(_index, item, block)
      block.call(item)
    end
    
    def next_batch_cursor
      @result&.collection_metadata&.next_page_cursor
    end

    def make_next_batch_available
      @result = fetch_batch(cursor: next_batch_cursor)
      raise PackAPI::InternalError.new(object: @result.errors) unless @result.success
    end

    def fetch_batch(cursor: nil)
      method.call(**kwargs.merge(optional_attributes:, per_page: batch_size, cursor:))
    end
  end
end
