module BabySqueel
  # Raised when a name in a DSL block is neither a column nor an association,
  # when #of is missing on a polymorphic association or used on a plain one,
  # and when a joined association cannot be found in Active Record's join tree.
  class Error < StandardError; end
end
