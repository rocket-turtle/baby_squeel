require "baby_squeel/dsl"

module BabySqueel
  module ActiveRecord
    module WhereChain
      # Constructs Arel for ActiveRecord::Base#where using the DSL. An array
      # of conditions is ANDed; Active Record itself would read an array as
      # a SQL template followed by its bind values.
      def has(&)
        conditions = DSL.new(@scope).evaluate(&)
        conditions = [conditions] unless conditions.is_a?(Array)
        conditions.each { |condition| where_condition!(condition) }
        @scope
      end

      private

      # A table unwraps to the hash joining passes to joins. As a where
      # condition that hash reads as `association: {}`, which Active Record
      # turns into 1=0, so it is rejected before it can.
      def where_condition!(condition)
        if condition.is_a?(BabySqueel::Table)
          raise ArgumentError, "where.has got #{condition.inspect} instead of a condition. Join it with joining."
        end

        condition = Nodes.unwrap(condition)
        @scope.where!(condition) unless condition.blank?
      end
    end
  end
end
