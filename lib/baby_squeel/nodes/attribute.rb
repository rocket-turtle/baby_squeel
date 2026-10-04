require "baby_squeel/nodes/proxy"

module BabySqueel
  module Nodes
    class Attribute < Proxy
      def initialize(parent, name)
        @parent = parent
        @name = name.to_s
        super(parent._table[@name])
      end

      def in(rel)
        rel.is_a?(::ActiveRecord::Relation) ? Nodes.wrap(subquery(rel)) : super
      end

      def not_in(rel)
        return super unless rel.is_a?(::ActiveRecord::Relation)

        node = subquery(rel)
        Nodes.wrap ::Arel::Nodes::NotIn.new(node.left, node.right)
      end

      def _arel
        if @parent.is_a?(BabySqueel::Association)
          @parent.find_alias[@name]
        else
          super
        end
      end

      private

      # Builds the IN node for a relation with the handler Active Record uses
      # for where(column: relation). It applies eager loading so the joins it
      # implies end up in the subquery, selects the primary key when the
      # relation selects nothing, rejects composite primary keys and keeps
      # the bind parameters.
      def subquery(rel)
        ::ActiveRecord::PredicateBuilder::RelationHandler.new.call(_arel, rel)
      end
    end
  end
end
