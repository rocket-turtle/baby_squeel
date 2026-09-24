require "baby_squeel/dsl"

module BabySqueel
  module ActiveRecord
    module WhereChain
      # Constructs Arel for ActiveRecord::Base#where using the DSL. An array
      # of conditions is ANDed; Active Record itself would read an array as
      # a SQL template followed by its bind values.
      def has(&)
        conditions = DSL.evaluate(@scope, &)
        conditions = [conditions] unless conditions.is_a?(Array)
        conditions.each { |condition| @scope.where!(condition) unless condition.blank? }
        @scope
      end
    end
  end
end
