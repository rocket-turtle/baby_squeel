require "baby_squeel/join"
require "baby_squeel/active_record/version_helper"

module BabySqueel
  module ActiveRecord
    # Prepended to ActiveRecord::Associations::JoinDependency.
    module JoinDependency
      private

      # Builds the JoinAssociations for one level of the association tree.
      # BabySqueel::Join keys carry a join type and, for a polymorphic
      # association, the class to join; every other key is Active Record's
      # own and goes through its builder, including its validity and
      # deprecation checks.
      def build(associations, base_klass)
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
        join_association.join_type = join.type
        join_association
      end

      # A copy of the polymorphic reflection whose klass is the given class.
      # Reflection#klass reads the memoized @klass, and the copy leaves the
      # original reflection untouched for other threads.
      def with_klass(reflection, klass)
        reflection.clone.tap { |copy| copy.instance_variable_set(:@klass, klass) }
      end

      def guard_deprecation(reflection)
        return unless VersionHelper.deprecated_associations?

        ::ActiveRecord::Associations::Deprecation.guard(reflection) { "referenced in query to join its table" }
      end

      # A child built from a BabySqueel::Join carries its own join type. An
      # outer one takes precedence over the join type of the surrounding
      # dependency, which is InnerJoin for joins_values, so that child is a
      # LEFT OUTER JOIN inside an otherwise inner join tree.
      def make_constraints(parent, child, join_type)
        join_type = child.join_type if child.join_type == Arel::Nodes::OuterJoin
        super
      end
    end
  end
end
