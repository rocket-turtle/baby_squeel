module Factories
  def create_table(klass)
    BabySqueel::Table.new(klass)
  end

  def create_dsl(klass)
    BabySqueel::DSL.new(klass)
  end

  def create_association(klass, association)
    BabySqueel::Association.new(
      create_table(klass),
      klass.reflect_on_association(association)
    )
  end
end
