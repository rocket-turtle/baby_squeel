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

  def new_join_dependency(klass, associations = {})
    ActiveRecord::Associations::JoinDependency.new klass, klass.arel_table, associations, Arel::Nodes::InnerJoin
  end

  def new_join(name, type = Arel::Nodes::InnerJoin, klass = nil)
    BabySqueel::Join.new name, type, klass
  end
end
