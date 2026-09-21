require "baby_squeel/nodes"
require "baby_squeel/relation"
require "baby_squeel/association"

module BabySqueel
  class DSL < Relation
    class << self
      def evaluate(scope, &) # :nodoc:
        Nodes.unwrap new(scope).evaluate(&)
      end
    end

    private

    def resolver
      @resolver ||= Resolver.new(self, %i[column association])
    end
  end
end
