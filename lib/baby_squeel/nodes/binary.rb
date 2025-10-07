require 'baby_squeel/nodes/proxy'

module BabySqueel
  module Nodes
    class Binary < Proxy
      def initialize(node)
        super
        node.extend Arel::AliasPredication
      end
    end
  end
end
