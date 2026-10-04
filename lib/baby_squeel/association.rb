require "baby_squeel/table"
require "baby_squeel/join"

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
      unless _reflection.polymorphic?
        raise Error, "'#{_reflection.name}' is not a polymorphic association, #of only applies to one."
      end
      raise ArgumentError, "#{klass.inspect} is not an Active Record model" unless model?(klass)

      clone.of! klass
    end

    def of!(klass)
      self._scope = klass
      self._table = klass.arel_table
      self._polymorphic_klass = klass
      self
    end

    # The key for this association in the hash Table#_arel hands to Active
    # Record: the name for an inner join, a Join carrying the join type and
    # the class for an outer join or a polymorphic association.
    def join_key
      if _join == Arel::Nodes::OuterJoin || _reflection.polymorphic?
        Join.new(_reflection.name, _join, _polymorphic_klass)
      else
        _reflection.name
      end
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
      polymorphic_class! if _reflection.polymorphic? && _polymorphic_klass.nil?

      @parent._arel([self, *associations])
    end

    private

    def polymorphic_class!
      raise Error, "'#{_reflection.name}' is a polymorphic association, name the class to join with " \
                   "#{_reflection.name}.of(SomeModel)."
    end

    def model?(klass)
      klass.is_a?(Class) && klass < ::ActiveRecord::Base
    end

    # A polymorphic association has no scope until #of names the class, so
    # there is nothing to resolve attributes or associations against.
    def respond_to_missing?(name, *)
      !_scope.nil? && super
    end

    def method_missing(*, &)
      polymorphic_class! if _scope.nil?

      super
    end
  end
end
