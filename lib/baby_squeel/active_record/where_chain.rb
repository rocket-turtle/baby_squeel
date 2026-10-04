require "baby_squeel/dsl"

module BabySqueel
  module ActiveRecord
    module WhereChain
      # Constructs Arel for ActiveRecord::Base#where using the DSL. The block
      # returns one condition. An array would reach where! as a SQL template
      # with bind values, and a table unwraps to the joins hash, which where!
      # reads as `association: {}` and turns into 1=0; both are rejected.
      def has(&)
        condition = DSL.new(@scope).evaluate(&)
        if condition.is_a?(Array) || condition.is_a?(BabySqueel::Table)
          raise ArgumentError, "where.has got #{condition.inspect} instead of a condition"
        end

        condition = Nodes.unwrap(condition)
        @scope.where!(condition) unless condition.blank?
        @scope
      end
    end
  end
end
