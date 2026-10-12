require "baby_squeel/active_record/version_helper"

module BabySqueel
  module ActiveRecord
    # Prepended to ActiveRecord::Associations::JoinDependency.
    module JoinDependency
      # Extends the copy of a polymorphic reflection made by #with_klass.
      module PolymorphicJoinScope
        # The type column holds the polymorphic_name of the joined class,
        # which for an STI subclass is the name of its base class.
        def join_scope(table, foreign_table, foreign_klass)
          super.where!(foreign_table[foreign_type].eq(klass.polymorphic_name))
        end
      end

      # Marks a JoinAssociation built from an outer BabySqueel::Join. An
      # instance variable rather than an extended module, which would give
      # every such join its own singleton class; not a subclass, because
      # JoinPart#match? compares classes when Active Record merges trees.
      OUTER = :@baby_squeel_outer

      private

      # Builds the JoinAssociations for one level of the association tree.
      # BabySqueel::Join keys carry an outer flag and, for a polymorphic
      # association, the class to join; every other key is Active Record's
      # own and goes through its builder, including its validity and
      # deprecation checks. The prepend sees every join of the application,
      # so a level without a Join goes to Active Record as it is.
      def build(associations, base_klass)
        return super unless associations.any? { |name, _| name.is_a?(Join) }

        associations.flat_map do |name, right|
          name.is_a?(Join) ? build_join(name, right, base_klass) : super({ name => right }, base_klass)
        end
      end

      def build_join(join, right, base_klass)
        reflection = find_reflection base_klass, join.name
        reflection.check_validity!
        reflection.check_eager_loadable!
        guard_deprecation(reflection)

        reflection = with_klass(reflection, join.klass) if join.klass
        children = build(right, reflection.klass)
        join_association = ::ActiveRecord::Associations::JoinDependency::JoinAssociation.new(reflection, children)
        join_association.instance_variable_set(OUTER, true) if join.outer
        join_association
      end

      # A copy of the polymorphic reflection whose klass is the given class
      # and whose join is constrained to it. Reflection#klass reads the
      # memoized @klass, and the copy leaves the original reflection
      # untouched for other threads.
      def with_klass(reflection, klass)
        reflection.clone.tap do |copy|
          copy.instance_variable_set(:@klass, klass)
          copy.extend(PolymorphicJoinScope)
        end
      end

      def guard_deprecation(reflection)
        return unless VersionHelper.deprecated_associations?

        ::ActiveRecord::Associations::Deprecation.guard(reflection) { "referenced in query to join its table" }
      end

      # A child marked OUTER takes precedence over the join type of the
      # surrounding dependency, which is InnerJoin for joins_values, so that
      # child is a LEFT OUTER JOIN inside an otherwise inner join tree.
      def make_constraints(parent, child, join_type)
        join_type = Arel::Nodes::OuterJoin if child.instance_variable_get(OUTER)
        super
      end
    end
  end
end
