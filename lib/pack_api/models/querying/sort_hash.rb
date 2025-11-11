# frozen_string_literal: true

module PackAPI::Querying
  class SortHash < Hash

    ###
    # Normalize a hash object to be used to control the sorting of a collection of objects
    #
    # @param [Hash|Symbol|String] sort_arg When provided with a string or a symbol, the sort hash will treat that
    # as the name of the attribute to sort by, and will sort in ascending order. When provided with a hash, the keys
    # of the hash should be the names of the attributes to sort by, and the values should be either `:asc` or `:desc`
    def initialize(sort_arg)
      super()
      case sort_arg
      when Arel::Nodes::SqlLiteral, nil
        hash_entries = []
      when Hash
        hash_entries = sort_arg.to_a
      when Symbol
        hash_entries = [[sort_arg, :asc]]
      when String
        hash_entries = sort_arg.split(',').map do |sort_term|
          sort_term_parts = sort_term.split
          [sort_term_parts[0].to_sym, sort_term_parts[1]&.to_sym || :asc]
        end
      end

      hash_entries.each do |key, value|
        next unless key.present?

        self[key] = value
      end
      deep_transform_values! { it.downcase.to_sym }
    end
  end
end
