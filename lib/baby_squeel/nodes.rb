require "baby_squeel/nodes/attribute"

module BabySqueel
  module Nodes
    class << self
      # Turns a DSL result into what Active Record accepts: a Table into the
      # joins hash, an array element by element, anything else as it is.
      def unwrap(node)
        if node.is_a? Table
          node._joins
        elsif node.is_a? Array
          node.map { |n| unwrap(n) }
        else
          node
        end
      end
    end
  end
end
