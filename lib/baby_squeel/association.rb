require "baby_squeel/table"
require "baby_squeel/nodes/attribute"

module BabySqueel
  class Association < Table
    # An Active Record association reflection
    attr_reader :_reflection, :_join

    def initialize(parent, reflection)
      @parent = parent
      @_reflection = reflection
      @_join = Arel::Nodes::InnerJoin
      super(reflection.polymorphic? ? nil : reflection.klass)
    end

    def inspect
      "#<#{self.class.name} #{_reflection.name}>"
    end

    # Names the class a polymorphic association joins with. It becomes the
    # scope of the association, which has none until then.
    def of(klass)
      unless _reflection.polymorphic?
        raise Error, "'#{_reflection.name}' is not a polymorphic association, #of only applies to one."
      end
      raise ArgumentError, "#{klass.inspect} is not an Active Record model" unless model?(klass)

      clone.scope! klass
    end

    # Instruct the association to be joined with a LEFT OUTER JOIN.
    def outer
      clone.outer!
    end

    # The key for this association in the hash DSL#_joins hands to Active
    # Record: the name for an inner join, a Join carrying the join type and
    # the class for an outer join or a polymorphic association. Joining and
    # resolving an alias both start from it, so a polymorphic association
    # without #of fails here.
    def join_key
      polymorphic_class! if _scope.nil?

      if _join == Arel::Nodes::OuterJoin || _reflection.polymorphic?
        Join.new(_reflection.name, _join, _reflection.polymorphic? ? _scope : nil)
      else
        _reflection.name
      end
    end

    # See BabySqueel::DSL#find_alias.
    def find_alias(associations = [])
      @parent.find_alias([self, *associations])
    end

    def [](key)
      Nodes::Attribute.from(find_alias[key])
    end

    # Passes this association up the tree until it hits the
    # BabySqueel::DSL, which builds the hash Active Record joins from.
    #
    #        Post.joining { author }
    #
    def _joins(associations = [])
      @parent._joins([self, *associations])
    end

    protected

    def outer!
      @_join = Arel::Nodes::OuterJoin
      self
    end

    def scope!(scope)
      @_scope = scope
      self
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
