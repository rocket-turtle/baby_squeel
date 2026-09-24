module Polyamorous
  module JoinDependencyExtensions
    # Builds the JoinAssociations for one level of the association tree.
    # Polyamorous::Join keys carry a join type and, for a polymorphic
    # association, the class to join; every other key is Active Record's own
    # and goes through its builder, including its validity and deprecation
    # checks.
    def build(associations, base_klass)
      associations.flat_map do |name, right|
        next super({ name => right }, base_klass) unless name.is_a?(Join)

        reflection = find_reflection base_klass, name.name
        reflection.check_validity!
        reflection.check_eager_loadable!
        guard_deprecation(reflection)

        klass = name.klass || reflection.klass
        JoinAssociation.new(reflection, build(right, klass), name.klass, name.type)
      end
    end

    private

    def guard_deprecation(reflection)
      return unless BabySqueel::ActiveRecord::VersionHelper.deprecated_associations?

      ::ActiveRecord::Associations::Deprecation.guard(reflection) { "referenced in query to join its table" }
    end

    # A child built from a Polyamorous::Join carries its own join type. An
    # outer one takes precedence over the join type of the surrounding
    # dependency, which is InnerJoin for joins_values, so that child is a LEFT
    # OUTER JOIN inside an otherwise inner join tree.
    def make_constraints(parent, child, join_type)
      join_type = child.join_type if child.join_type == Arel::Nodes::OuterJoin
      super
    end
  end
end
