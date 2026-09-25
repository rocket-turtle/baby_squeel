require "baby_squeel/nodes"
require "baby_squeel/association"

module BabySqueel
  class DSL < Table
    class << self
      def evaluate(scope, &) # :nodoc:
        Nodes.unwrap new(scope).evaluate(&)
      end
    end
  end
end
