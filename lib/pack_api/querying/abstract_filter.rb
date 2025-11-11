# frozen_string_literal: true

module PackAPI::Querying
  class AbstractFilter
    def present?
      false
    end

    ###
    # Applies the filter to the given query.
    # @param [ComposableQuery] query the active record relation to apply the filter to
    def apply_to(query)
    end
  end
end