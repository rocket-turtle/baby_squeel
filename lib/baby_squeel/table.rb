module BabySqueel
  # The base of DSL, the table of the scope, and Association: a scope whose
  # columns and associations resolve by name.
  class Table
    attr_reader :_scope

    # scope is the model class names resolve on. A polymorphic association
    # passes nil until #of names the class.
    def initialize(scope)
      @_scope = scope
    end

    private

    def column?(name)
      _scope.column_names.include?(name.to_s)
    end

    def association?(name)
      !_scope.reflect_on_association(name).nil?
    end

    def respond_to_missing?(name, *)
      column?(name) || association?(name) || super
    end

    # A column or association name without arguments resolves; anything else
    # is a NoMethodError as usual.
    def method_missing(name, *args, &block)
      return super if args.any? || block

      if column?(name)
        self[name]
      elsif (reflection = _scope.reflect_on_association(name))
        Association.new(self, reflection)
      else
        raise Error, "There is no column or association named '#{name}' for #{_scope.model_name}."
      end
    end
  end
end
