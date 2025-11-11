# frozen_string_literal: true

module PackAPI::Mapping
  class NullTransformer < AbstractTransformer
    def execute
      nil
    end
  end
end