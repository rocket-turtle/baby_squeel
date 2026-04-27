require "baby_squeel/table"

module BabySqueel
  class Relation < Table
    attr_accessor :_scope

    def initialize(scope)
      super(scope.arel_table)
      @_scope = scope
    end

    # Constructs a new BabySqueel::Association. Raises
    # an exception if the association is not found.
    def association(name)
      reflection = _scope.reflect_on_association(name)
      if reflection
        Association.new(self, reflection)
      else
        raise AssociationNotFoundError.new(_scope.model_name, name)
      end
    end

    private

    def resolver
      @resolver ||= Resolver.new(self, %i[column association])
    end
  end
end
