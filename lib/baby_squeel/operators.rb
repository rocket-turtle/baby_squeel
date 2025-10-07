module BabySqueel
  module Operators
    module ArelAliasing
      # Allows the creation of shorthands for Arel methods.
      #
      # ==== Arguments
      #
      # * +operator+ - A custom operator.
      # * +arel_name+ - The name of the Arel method you want to alias.
      #
      # ==== Example
      #    BabySqueel::Nodes::Node.arel_alias :unlike, :does_not_match
      #    Post.where.has { title.unlike 'something' }
      #
      def arel_alias(operator, arel_name)
        define_method operator do |other|
          send(arel_name, other)
        end
      end
    end

    module Equality
      extend ArelAliasing
      arel_alias :==, :eq
      arel_alias :'!=', :not_eq
    end

    module Generic
      # Create a SQL operation. See Arel::Nodes::InfixOperation.
      #
      # ==== Arguments
      #
      # * +operator+ - A SQL operator.
      # * +other+ - The argument to be passed to the SQL operator.
      #
      # ==== Example
      #    Post.selecting { title.op('||', quoted('diddly')) }
      #    #=> SELECT "posts"."title" || 'diddly' FROM "posts"
      #
      def op(operator, other)
        Nodes.wrap Arel::Nodes::InfixOperation.new(operator, self, other)
      end
    end
  end
end
