module BabySqueel
  module ActiveRecord
    # Prepended to ActiveRecord::Reflection::AbstractReflection.
    module Reflection
      # Constrains a polymorphic belongs_to to the joined class. The type
      # column holds the polymorphic_name of that class, which for an STI
      # subclass is the name of its base class.
      def join_scope(table, foreign_table, foreign_klass)
        if respond_to?(:polymorphic?) && polymorphic?
          super.where!(foreign_table[foreign_type].eq(klass.polymorphic_name))
        else
          super
        end
      end
    end
  end
end
