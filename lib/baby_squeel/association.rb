require "baby_squeel/table"

module BabySqueel
  class Association < Table
    # An Active Record association reflection
    attr_reader :_reflection

    # Specifies the model that the polymorphic
    # association should join with
    attr_accessor :_polymorphic_klass

    def initialize(parent, reflection)
      @parent = parent
      @_reflection = reflection

      # In the case of a polymorphic reflection these
      # attributes will be set after calling #of
      return if @_reflection.polymorphic?

      super(@_reflection.klass)
    end

    def of(klass)
      raise PolymorphicSpecificationError.new(_reflection.name, klass) unless _reflection.polymorphic?
      raise ArgumentError, "#{klass.inspect} is not an Active Record model" unless model?(klass)

      clone.of! klass
    end

    def of!(klass)
      self._scope = klass
      self._table = klass.arel_table
      self._polymorphic_klass = klass
      self
    end

    def needs_polyamorous?
      _join == Arel::Nodes::OuterJoin || _reflection.polymorphic?
    end

    # The key BabySqueel::Table#_arel uses for this association when the
    # chain needs Polyamorous.
    def polyamorous_join
      Polyamorous::Join.new(_reflection.name, _join, _polymorphic_klass)
    end

    # See BabySqueel::Table#find_alias.
    def find_alias(associations = [])
      @parent.find_alias([self, *associations])
    end

    # Passes this association up the tree until it hits the top-level
    # BabySqueel::Table, which builds the hash Active Record joins from.
    #
    #        Post.joining { author }
    #
    def _arel(associations = [])
      raise PolymorphicNotSpecifiedError, _reflection.name if _reflection.polymorphic? && _polymorphic_klass.nil?

      @parent._arel([self, *associations])
    end

    private

    def model?(klass)
      klass.is_a?(Class) && klass < ::ActiveRecord::Base
    end

    # A polymorphic association has no scope until #of names the class, so
    # there is nothing to resolve attributes or associations against.
    def respond_to_missing?(name, *)
      !_scope.nil? && super
    end

    def method_missing(*, &)
      raise PolymorphicNotSpecifiedError, _reflection.name if _scope.nil?

      super
    end
  end
end
