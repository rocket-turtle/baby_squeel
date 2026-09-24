module Polyamorous
  module SwappingReflectionClass
    # Returns a copy of the polymorphic reflection whose klass is the given
    # class. Reflection#klass reads the memoized @klass, and the copy leaves
    # the original reflection untouched for other threads.
    def swapping_reflection_klass(reflection, klass)
      new_reflection = reflection.clone
      new_reflection.instance_variable_set(:@klass, klass)
      yield new_reflection
    end
  end
end
