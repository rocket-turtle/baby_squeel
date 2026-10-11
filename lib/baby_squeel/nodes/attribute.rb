module BabySqueel
  module Nodes
    # Extends an Arel attribute of the table the final query will use with
    # IN and NOT IN accepting a relation as a subquery.
    #
    # An extension of the instance, not a subclass: Arel's attribute is a
    # Struct, whose == compares the class, and Active Record relies on that
    # equality in rewhere and merge to find the predicate of a
    # column.
    module Attribute
      # The DSL attribute for an attribute built by Arel::Table#[], which
      # resolves an alias_attribute name to the column.
      def self.from(arel_attribute)
        arel_attribute.extend(self)
      end

      def in(rel)
        rel.is_a?(::ActiveRecord::Relation) ? subquery(rel) : super
      end

      def not_in(rel)
        rel.is_a?(::ActiveRecord::Relation) ? subquery(rel).invert : super
      end

      private

      # Builds the IN node for a relation with the handler Active Record uses
      # for where(column: relation). It applies eager loading so the joins it
      # implies end up in the subquery, selects the primary key when the
      # relation selects nothing, rejects composite primary keys and keeps
      # the bind parameters.
      def subquery(rel)
        ::ActiveRecord::PredicateBuilder::RelationHandler.new.call(self, rel)
      end
    end
  end
end
