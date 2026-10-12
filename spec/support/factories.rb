module Factories
  def create_dsl(klass)
    BabySqueel::DSL.new(klass.all)
  end

  def create_association(klass, association)
    BabySqueel::Association.new(
      create_dsl(klass),
      klass.reflect_on_association(association)
    )
  end

  def new_join_dependency(klass, associations = {})
    ActiveRecord::Associations::JoinDependency.new klass, klass.arel_table, associations, Arel::Nodes::InnerJoin
  end

  def new_join(name, outer: false, klass: nil)
    BabySqueel::Join.new name, outer, klass
  end
end
