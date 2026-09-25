module BabySqueel
  class NotFoundError < StandardError # :nodoc:
    def initialize(model_name, name, strategies)
      super("There is no #{strategies.join(' or ')} named '#{name}' for #{model_name}.")
    end
  end

  class AssociationNotFoundError < StandardError # :nodoc:
    def initialize(model_name, name)
      super("Association named '#{name}' was not found for #{model_name}.")
    end
  end

  class PolymorphicSpecificationError < StandardError # :nodoc:
    MESSAGE =
      "'%{association}' is not a polymorphic association, therefore " \
      "the following expression is invalid:" \
      "\n\n  %{association}.of(%{klass})\n\n".freeze

    def initialize(association, klass)
      super(format(MESSAGE, association: association, klass: klass))
    end
  end

  class PolymorphicNotSpecifiedError < StandardError # :nodoc:
    MESSAGE =
      "'%{association}' is a polymorphic association, therefore " \
      "you must call #of when referencing the association. For example:" \
      "\n\n  %{association}.of(SomeModel)\n\n".freeze

    def initialize(association)
      super(format(MESSAGE, association: association))
    end
  end
end
