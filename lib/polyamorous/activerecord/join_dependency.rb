module Polyamorous
  module JoinDependencyExtensions
    # Replaces ActiveRecord::Associations::JoinDependency#build
    def build(associations, base_klass)
      associations.map do |name, right|
        if name.is_a? Join
          reflection = find_reflection base_klass, name.name
          reflection.check_validity!
          reflection.check_eager_loadable!

          klass = if reflection.polymorphic?
                    name.klass || base_klass
                  else
                    reflection.klass
                  end
          JoinAssociation.new(reflection, build(right, klass), name.klass, name.type)
        else
          reflection = find_reflection base_klass, name
          reflection.check_validity!
          reflection.check_eager_loadable!

          raise ActiveRecord::EagerLoadPolymorphicError, reflection if reflection.polymorphic?

          JoinAssociation.new(reflection, build(right, reflection.klass))
        end
      end
    end

    private

    # A child built from a Polyamorous::Join carries its own join type. An
    # outer one takes precedence over the join type of the surrounding
    # dependency, which is InnerJoin for joins_values, so that child is a LEFT
    # OUTER JOIN inside an otherwise inner join tree.
    def make_constraints(parent, child, join_type)
      join_type = child.join_type if child.join_type == Arel::Nodes::OuterJoin
      super
    end

    module ClassMethods
      # TreeNode covers both Polyamorous::Join and BabySqueel::Join, whose
      # #add_to_tree expands a whole chain instead of adding one key. Every
      # other shape is Active Record's own, including its nil-value guard.
      def walk_tree(associations, hash)
        associations.is_a?(TreeNode) ? associations.add_to_tree(hash) : super
      end
    end
  end
end
