require "baby_squeel/dsl"
require "baby_squeel/join_dependency"

module BabySqueel
  module ActiveRecord
    module QueryMethods
      # This class allows BabySqueel to slip custom
      # joins_values into Active Record's JoinDependency
      module JoinsInjector
        def each(&block)
          super do |join|
            if join.is_a?(BabySqueel::Join)
              result = block.binding.local_variables.include?(:result) && block.binding.local_variable_get(:result)
              result << join if result
              join
            else
              block.call(join)
            end
          end
        end
      end

      # Constructs Arel for ActiveRecord::QueryMethods#joins using the DSL.
      def joining(&)
        joins DSL.evaluate(self, &)
      end

      def construct_join_dependency(associations, join_type)
        result = super
        result.extend(BabySqueel::JoinDependency::OuterJoinConstraints) if associations.any?(BabySqueel::Join)
        result
      end

      private

      # https://github.com/rails/rails/commit/c0c53ee9d28134757cf1418521cb97c4a135f140
      def select_association_list(*args)
        args[0].extend(BabySqueel::ActiveRecord::QueryMethods::JoinsInjector) if args[0].any?(BabySqueel::Join)
        super
      end
    end
  end
end
