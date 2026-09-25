module BabySqueel
  module ActiveRecord
    # Prepended to ActiveRecord::Associations::JoinDependency::JoinAssociation.
    module JoinAssociation
      attr_reader :join_type

      def initialize(reflection, children, polymorphic_class = nil, join_type = Arel::Nodes::InnerJoin)
        @join_type = join_type
        reflection = with_klass(reflection, polymorphic_class) if polymorphic_class
        super(reflection, children)
      end

      private

      # A copy of the polymorphic reflection whose klass is the given class.
      # Reflection#klass reads the memoized @klass, and the copy leaves the
      # original reflection untouched for other threads.
      def with_klass(reflection, klass)
        reflection.clone.tap { |copy| copy.instance_variable_set(:@klass, klass) }
      end
    end
  end
end
