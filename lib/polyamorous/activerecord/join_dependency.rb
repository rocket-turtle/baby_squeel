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

    def construct_tables_for_association!(join_root, association)
      tables = table_aliases_for(join_root, association)
      association.table = tables.first
      tables
    end

    private

    def table_aliases_for(parent, node)
      @joined_tables ||= {}
      node.reflection.chain.map do |reflection|
        table, terminated = @joined_tables[reflection]
        root = reflection == node.reflection

        if table && (!root || !terminated)
          @joined_tables[reflection] = [table, true] if root
        else
          table = alias_tracker.aliased_table_for(reflection.klass.arel_table) do
            name = reflection.alias_candidate(parent.table_name)
            root ? name : "#{name}_join"
          end
          @joined_tables[reflection] ||= [table, root] if join_type == Arel::Nodes::OuterJoin
        end
        table
      end
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
