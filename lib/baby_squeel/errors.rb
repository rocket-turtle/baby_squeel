module BabySqueel
  # Raised when a name in a DSL block does not resolve, or when a polymorphic
  # association is used without or a plain association with #of.
  class Error < StandardError; end
end
