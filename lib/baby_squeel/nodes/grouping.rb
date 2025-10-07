require 'baby_squeel/nodes/proxy'

module BabySqueel
  module Nodes
    # See: https://github.com/rails/arel/pull/435
    class Grouping < Proxy
      def initialize(node)
        super
        node.extend Arel::AliasPredication
        node.extend Arel::OrderPredications
        node.extend Arel::Expressions
      end
    end
  end
end
