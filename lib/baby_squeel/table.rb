module BabySqueel
  class Table
    attr_accessor :_table, :_scope, :_join

    # scope is a model class or a relation; both answer arel_table,
    # column_names and reflect_on_association. A polymorphic association
    # passes nil until #of names the class.
    def initialize(scope)
      @_scope = scope
      @_table = scope&.arel_table
      @_join = Arel::Nodes::InnerJoin
    end

    # Constructs a new BabySqueel::Association. Raises
    # an exception if the association is not found.
    def association(name)
      reflection = _scope.reflect_on_association(name)
      raise Error, "Association named '#{name}' was not found for #{_scope.model_name}." unless reflection

      Association.new(self, reflection)
    end

    def inspect
      "#<#{self.class.name} #{_table.name}>"
    end

    # See Arel::Table#[]
    def [](key)
      Nodes::Attribute.new(self, key)
    end

    # Instruct the table to be joined with a LEFT OUTER JOIN.
    def outer
      clone.outer!
    end

    def outer! # :nodoc:
      self._join = Arel::Nodes::OuterJoin
      self
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

    # When referencing a joined table, the tables that
    # attributes reference can change (due to aliasing).
    # This method allows BabySqueel::Nodes::Attribute
    # instances to find what their alias will be.
    #
    # Resolving means building the join dependency of the scope, so the
    # result is kept per chain for the lifetime of this table, which is one
    # DSL block. The scope does not change within it.
    def find_alias(associations = [])
      @aliases ||= {}
      @aliases[associations.map(&:join_key)] ||= begin
        rel = _scope.joins _arel(associations)
        find_join_association(join_root(rel), associations).table
      end
    end

    # This method will be invoked by BabySqueel::Nodes::unwrap. Active
    # Record gets a nested hash, one key per association in the chain (see
    # Association#join_key). Names as keys let Active Record merge the chain
    # with its own joins of the same association.
    def _arel(associations = [])
      return unless associations.any?

      associations.reverse.inject({}) do |children, assoc|
        { assoc.join_key => children }
      end
    end

    private

    # The join root of the join dependency Active Record would build for
    # relation.arel (see ActiveRecord::QueryMethods#build_joins), so each
    # JoinAssociation carries the table the final query will use.
    def join_root(relation)
      buckets, join_type = relation.send(:build_join_buckets)
      alias_tracker = relation.alias_tracker(buckets[:leading_join] + buckets[:join_node])
      join_dependency = relation.construct_join_dependency(buckets[:named_join], join_type)
      join_dependency.join_constraints(buckets[:stashed_join], alias_tracker, relation.references_values)
      join_dependency.send(:join_root)
    end

    # Walks the chain of associations down the join tree. A polymorphic
    # association is matched by the class it was joined with.
    def find_join_association(current, associations)
      associations.each do |association|
        current = current.children.find do |child|
          child.reflection.name == association._reflection.name &&
            (!association._reflection.polymorphic? || association._polymorphic_klass == child.base_klass)
        end
        break if current.nil?
      end

      current
    end

    def column?(name)
      _scope.column_names.include?(name.to_s)
    end

    def association?(name)
      !_scope.reflect_on_association(name).nil?
    end

    def respond_to_missing?(name, *)
      column?(name) || association?(name) || super
    end

    # A column or association name without arguments resolves; anything else
    # is a NoMethodError as usual.
    def method_missing(name, *args, &block)
      return super if args.any? || block

      if column?(name)
        self[name]
      elsif association?(name)
        association(name)
      else
        raise Error, "There is no column or association named '#{name}' for #{_scope.model_name}."
      end
    end
  end
end
