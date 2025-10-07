require 'baby_squeel/nodes'
require 'baby_squeel/relation'
require 'baby_squeel/association'

module BabySqueel
  class DSL < Relation
    class << self
      def evaluate(scope, &block) # :nodoc:
        Nodes.unwrap new(scope).evaluate(&block)
      end
    end

    private

    def resolver
      @resolver ||= Resolver.new(self, [:column, :association])
    end
  end
end
