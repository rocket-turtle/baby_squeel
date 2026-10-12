require "baby_squeel/dsl"

module BabySqueel
  module ActiveRecord
    module QueryMethods
      # Constructs Arel for ActiveRecord::QueryMethods#joins using the DSL.
      # The block returns a table or anything joins takes, or an array of
      # them; a table becomes the joins hash of its chain.
      def joining(&)
        nodes = Array.wrap(DSL.new(self).evaluate(&)).flatten
        joins(nodes.map { |node| node.is_a?(Table) ? node._joins : node })
      end
    end
  end
end
