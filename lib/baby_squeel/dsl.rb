require "baby_squeel/association"

module BabySqueel
  # The receiver of a joining or where.has block: the table of the scope.
  class DSL < Table
    # Evaluates a DSL block. If arity is given, this method
    # `yield` itself, rather than `instance_eval`.
    def evaluate(&block)
      if block.arity.zero?
        instance_eval(&block)
      else
        yield(self)
      end
    end
  end
end
