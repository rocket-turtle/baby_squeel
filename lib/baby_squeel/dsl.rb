require "baby_squeel/association"

module BabySqueel
  # The receiver of a joining or where.has block: the table of the scope.
  class DSL < Table
    # Names resolve on the model: a relation answers column_names,
    # reflect_on_association and arel_table only by delegating to it. The
    # relation itself is kept for the join trees the aliases come from.
    def initialize(relation)
      @relation = relation
      super(relation.model)
    end

    def _table
      _scope.arel_table
    end

    def inspect
      "#<#{self.class.name} #{_table.name}>"
    end

    # Evaluates a DSL block. If arity is given, this method
    # `yield` itself, rather than `instance_eval`.
    def evaluate(&block)
      if block.arity.zero?
        instance_eval(&block)
      else
        yield(self)
      end
    end

    # See Arel::Table#[]. Association#[] gives the attribute of its alias.
    def [](key)
      Nodes::Attribute.from(_table[key])
    end

    # When referencing a joined table, the tables that
    # attributes reference can change (due to aliasing).
    # This method allows BabySqueel::Nodes::Attribute
    # instances to find what their alias will be.
    #
    # The chain is looked up in the joins the scope already has, inner and
    # outer, so the alias is the one of the final query whichever way the
    # scope joined it. A chain the scope does not join is added as an inner
    # join first; Active Record then aliases it as it would in the query.
    #
    # Resolving means building the join dependency of the scope, so the
    # result is kept per chain for the lifetime of the DSL, which is one
    # block. The scope does not change within it.
    def find_alias(associations = [])
      @aliases ||= {}
      @aliases[associations.map(&:join_key)] ||= resolve(associations).table
    end

    # The nested hash Active Record joins from, one key per association in
    # the chain (see Association#join_key). Names as keys let Active Record
    # merge the chain with its own joins of the same association.
    def _joins(associations = [])
      return unless associations.any?

      associations.reverse.inject({}) do |children, assoc|
        { assoc.join_key => children }
      end
    end

    private

    def resolve(associations)
      find_join_association(scope_roots, associations) ||
        find_join_association(join_roots(@relation.joins(_joins(associations))), associations) ||
        raise(Error, "Active Record's join tree has no join for '#{associations.last._reflection.name}'.")
    end

    # The join trees of the scope as it is, built once per DSL block.
    def scope_roots
      @scope_roots ||= join_roots(@relation)
    end

    # The join roots of the join dependencies Active Record would build for
    # relation.arel (see ActiveRecord::QueryMethods#build_joins): the one of
    # the inner joins first, then the stashed ones of left_joins, so each
    # JoinAssociation carries the table the final query will use.
    def join_roots(relation)
      buckets, join_type = relation.send(:build_join_buckets)
      alias_tracker = relation.alias_tracker(buckets[:leading_join] + buckets[:join_node])
      join_dependency = relation.construct_join_dependency(buckets[:named_join], join_type)
      stashed = buckets[:stashed_join].map { |dependency| copy_join_dependency(dependency) }
      join_dependency.join_constraints(stashed, alias_tracker, relation.references_values)
      [join_dependency, *stashed].map { |dependency| dependency.send(:join_root) }
    end

    # join_constraints assigns each JoinAssociation its table once and keeps
    # it. A join dependency merged in from another model is the object the
    # scope holds, so walking it here would fix its tables for the final
    # query, which may join more. The walk gets a copy of its tree.
    def copy_join_dependency(dependency)
      dependency.clone.tap do |copy|
        copy.instance_variable_set(:@join_root, copy_join_part(dependency.send(:join_root)))
      end
    end

    def copy_join_part(part)
      part.clone.tap do |copy|
        copy.instance_variable_set(:@children, part.children.map { |child| copy_join_part(child) })
      end
    end

    # The JoinAssociation at the end of the chain in the first join tree
    # that has the whole chain, nil when none has. A tree merged in from
    # another model joins from that model's table and is skipped.
    def find_join_association(roots, associations)
      roots.each do |root|
        next unless root.table == _table

        node = associations.inject(root) { |parent, association| find_child(parent, association) || break }
        return node if node
      end

      nil
    end

    # A polymorphic association is matched by the class it was joined with.
    def find_child(parent, association)
      parent.children.find do |child|
        child.reflection.name == association._reflection.name &&
          (!association._reflection.polymorphic? || association._scope == child.base_klass)
      end
    end
  end
end
