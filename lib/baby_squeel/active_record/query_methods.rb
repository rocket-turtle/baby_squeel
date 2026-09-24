require "baby_squeel/dsl"

module BabySqueel
  module ActiveRecord
    module QueryMethods
      # Constructs Arel for ActiveRecord::QueryMethods#joins using the DSL.
      def joining(&)
        joins DSL.evaluate(self, &)
      end
    end
  end
end
