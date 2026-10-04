require "baby_squeel/nodes/proxy"
require "baby_squeel/nodes/attribute"

module BabySqueel
  module Nodes
    class << self
      # Wraps an Arel node in a Proxy so that methods called on it return
      # wrapped nodes again; anything else passes through untouched.
      def wrap(arel)
        arel.is_a?(Arel::Nodes::Node) ? Proxy.new(arel) : arel
      end

      # Turns a DSL result into what Active Record accepts: a Proxy into its
      # Arel node, a Table into the joins hash, an array element by element.
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
