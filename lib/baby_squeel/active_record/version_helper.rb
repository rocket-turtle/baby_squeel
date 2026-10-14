module BabySqueel
  module ActiveRecord
    # The single place for Active Record version branches. Keeping them
    # together makes them easy to find and drop once support for a version
    # ends.
    class VersionHelper
      # Active Record 8.1 reports associations declared with deprecated: true
      # when they are joined.
      def self.deprecated_associations?
        defined?(::ActiveRecord::Associations::Deprecation) ? true : false
      end

      # The joins of a relation grouped as ActiveRecord::QueryMethods#build_joins
      # groups them: the join nodes the alias tracker counts, the association
      # names, the stashed join dependencies and the join type. Active Record
      # main returns them as a QueryMethods::JoinBuckets, 8.1 and earlier as a
      # Hash and the join type.
      def self.join_buckets(relation)
        buckets = relation.send(:build_join_buckets)
        if buckets.respond_to?(:named_joins)
          [buckets.leading_joins + buckets.join_nodes, buckets.named_joins, buckets.stashed_joins, buckets.join_type]
        else
          buckets, join_type = buckets
          [buckets[:leading_join] + buckets[:join_node], buckets[:named_join], buckets[:stashed_join], join_type]
        end
      end
    end
  end
end
