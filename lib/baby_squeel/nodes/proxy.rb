module BabySqueel
  module Nodes
    # This proxy class allows us to quack like any arel object. When a
    # method missing is hit, we'll instantiate a new proxy object.
    class Proxy < BasicObject
      # Resolve constants the normal way
      def self.const_missing(name)
        ::Object.const_get(name)
      end

      attr_reader :_arel

      def initialize(arel)
        @_arel = Nodes.unwrap(arel)
      end

      def inspect
        "BabySqueel{#{super}}"
      end

      def respond_to?(meth, include_private = false)
        meth.to_s == "_arel" || _arel.respond_to?(meth, include_private)
      end

      # BasicObject defines == and != as identity and ! as negation. On a
      # node they would turn `title == "x"` into a silently dropped
      # condition. Arel spells these eq, not_eq and not.
      def ==(_other) = ::Kernel.raise(::NoMethodError, "use #eq instead of == on #{inspect}")
      def !=(_other) = ::Kernel.raise(::NoMethodError, "use #not_eq instead of != on #{inspect}")
      def ! = ::Kernel.raise(::NoMethodError, "use #not instead of ! on #{inspect}")

      private

      def method_missing(meth, *args, &)
        if _arel.respond_to?(meth)
          Nodes.wrap _arel.send(meth, *Nodes.unwrap(args), &)
        else
          super
        end
      end
    end
  end
end
