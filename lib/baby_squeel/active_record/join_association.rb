module BabySqueel
  module ActiveRecord
    # Prepended to ActiveRecord::Associations::JoinDependency::JoinAssociation.
    # JoinDependency#build sets the type for a child built from a
    # BabySqueel::Join; everything else is an inner join.
    module JoinAssociation
      attr_writer :join_type

      def join_type
        @join_type || Arel::Nodes::InnerJoin
      end
    end
  end
end
