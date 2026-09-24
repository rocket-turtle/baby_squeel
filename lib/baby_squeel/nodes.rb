require "baby_squeel/nodes/proxy"
require "baby_squeel/nodes/attribute"

module BabySqueel
  module Nodes
    class << self
      # Wraps an Arel node in a Proxy so that methods called on it return
      # wrapped nodes again. Proxy covers every node type: Arel::Nodes::Binary
      # and Arel::Nodes::Grouping bring the alias, order and math predications
      # with them through Arel::Nodes::NodeExpression.
      def wrap(arel)
        arel.is_a?(Arel::Nodes::Node) ? Proxy.new(arel) : arel
      end

      # Unwraps a BabySqueel::Proxy before being passed to
      # ActiveRecord.
      def unwrap(node)
        if node.respond_to? :_arel
          unwrap node._arel
        elsif node.is_a? Array
          node.map { |n| unwrap(n) }
        else
          node
        end
      end
    end
  end
end
