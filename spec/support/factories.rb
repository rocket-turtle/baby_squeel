module Factories
  # Active Record 8.2 turned Arel::Table's positional name into a keyword argument.
  TABLE_NAME_AS_KEYWORD = Arel::Table.instance_method(:initialize).parameters.include?(%i[key name])

  def create_table(name)
    table = TABLE_NAME_AS_KEYWORD ? Arel::Table.new(name: name) : Arel::Table.new(name)
    BabySqueel::Table.new(table)
  end

  def create_dsl(klass)
    BabySqueel::DSL.new(klass)
  end

  def create_relation(klass)
    BabySqueel::Relation.new(klass)
  end

  def create_association(klass, association)
    BabySqueel::Association.new(
      create_relation(klass),
      klass.reflect_on_association(association)
    )
  end
end
