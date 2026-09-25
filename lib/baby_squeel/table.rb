require "baby_squeel/resolver"
require "baby_squeel/join_dependency"

module BabySqueel
  class Table
    attr_accessor :_table, :_scope
    attr_writer :_join

    # scope is a model class or a relation; both answer arel_table,
    # column_names and reflect_on_association.
    def initialize(scope)
      @_scope = scope
      @_table = scope.arel_table
    end

    # Constructs a new BabySqueel::Association. Raises
    # an exception if the association is not found.
    def association(name)
      reflection = _scope.reflect_on_association(name)
      raise AssociationNotFoundError.new(_scope.model_name, name) unless reflection

      Association.new(self, reflection)
    end

    def inspect
      "#<#{self.class.name} #{_table&.name}>"
    end

    # See Arel::Table#[]
    def [](key)
      Nodes::Attribute.new(self, key)
    end

    def _join
      @_join ||= Arel::Nodes::InnerJoin
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
    def find_alias(associations = [])
      rel = _scope.joins _arel(associations)
      builder = JoinDependency::Builder.new(rel)
      builder.find_alias(associations)
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

    # Built per call: outer works on a clone, and a resolver kept in an
    # instance variable would still point at the original table.
    def resolver
      Resolver.new(self, %i[column association])
    end

    def respond_to_missing?(name, *)
      resolver.resolves?(name) || super
    end

    def method_missing(*, &)
      resolver.resolve!(*, &) || super
    end
  end
end
