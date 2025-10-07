require 'baby_squeel/nodes/proxy'

module BabySqueel
  module Nodes
    # This is a generic proxy class that includes all possible modules.
    # In the future, these proxy classes should be more specific and only
    # include necessary/applicable modules.
    class Node < Proxy
      def initialize(node)
        super
        node.extend Arel::Math
      end
    end
  end
end
