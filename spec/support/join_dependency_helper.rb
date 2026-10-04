module JoinDependencyHelper
  def new_join_dependency(klass, associations = {})
    ActiveRecord::Associations::JoinDependency.new klass, klass.arel_table, associations, Arel::Nodes::InnerJoin
  end

  def new_join(name, type = Arel::Nodes::InnerJoin, klass = nil)
    BabySqueel::Join.new name, type, klass
  end
end
