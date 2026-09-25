module BabySqueel
  module JoinDependency
    class Builder # :nodoc:
      def initialize(relation)
        @relation = relation
      end

      # Find the alias of a BabySqueel::Association, by passing a list (in
      # order of chaining) of associations and finding the respective
      # JoinAssociation at each level.
      #
      # The join dependency is built the same way Active Record builds it for
      # relation.arel (see ActiveRecord::QueryMethods#build_joins), so the
      # table each JoinAssociation ends up with is the one the final query
      # will use.
      def find_alias(associations)
        buckets, join_type = @relation.send(:build_join_buckets)
        alias_tracker = @relation.alias_tracker(buckets[:leading_join] + buckets[:join_node])
        join_dependency = @relation.construct_join_dependency(buckets[:named_join], join_type)
        join_dependency.join_constraints(buckets[:stashed_join], alias_tracker, @relation.references_values)

        find_join_association(join_dependency.send(:join_root), associations).table
      end

      private

      def find_join_association(current, associations)
        associations.each do |association|
          name = association._reflection.name
          current = current.children.find { |c| c.reflection.name == name && klass_equal?(association, c) }
          break if current.nil?
        end

        current
      end

      # If association is not polymorphic return true.
      # If association is polymorphic compare the association polymorphic class with the join association base_klass
      def klass_equal?(assoc, join_association)
        return true unless assoc._reflection.polymorphic?

        assoc._polymorphic_klass == join_association.base_klass
      end
    end
  end
end
