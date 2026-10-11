require "baby_squeel/dsl"

module BabySqueel
  module ActiveRecord
    module WhereChain
      # Constructs Arel for ActiveRecord::Base#where using the DSL. The block
      # returns one condition in a form where! takes as such: nil, a String,
      # a Hash or an Arel node. Anything else is rejected: an array would
      # reach where! as a SQL template with bind values, a table makes where!
      # raise "Unsupported argument type" without naming the block's result,
      # and where! drops the false that `==` on an attribute mostly returns.
      def has(&)
        condition = DSL.new(@scope).evaluate(&)

        case condition
        when nil, String, Hash, Arel::Nodes::Node
          @scope.where!(condition) unless condition.blank?
        else
          raise ArgumentError, "where.has got #{rejected(condition)} instead of a condition"
        end

        @scope
      end

      private

      # Inspecting an array prints every node in it, inspecting an attribute
      # its table with the model's columns.
      def rejected(condition)
        case condition
        when Array then "an Array of #{condition.size}"
        when Arel::Attributes::Attribute then "the attribute #{condition.relation.name}.#{condition.name}"
        else condition.inspect
        end
      end
    end
  end
end
