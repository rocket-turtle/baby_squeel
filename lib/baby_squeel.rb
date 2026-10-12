require "active_record"
require "baby_squeel/version"

module BabySqueel
  # Raised when a name in a DSL block is neither a column nor an association,
  # when #of is missing on a polymorphic association or used on a plain one,
  # and when a joined association cannot be found in Active Record's join tree.
  class Error < StandardError; end

  # A key in the association tree Active Record's JoinDependency walks. Where
  # a plain key is the association name, a Join also carries the join type
  # and the class a polymorphic association is joined with. As a Data value
  # it compares by content, so Active Record dedupes equal joins like names.
  Join = Data.define(:name, :type, :klass)
end

ActiveSupport.on_load :active_record do
  require "baby_squeel/active_record/query_methods"
  require "baby_squeel/active_record/where_chain"
  require "baby_squeel/active_record/join_dependency"
  require "baby_squeel/active_record/join_association"

  ActiveRecord::Base.singleton_class.delegate :joining, to: :all
  ActiveRecord::Relation.prepend BabySqueel::ActiveRecord::QueryMethods
  ActiveRecord::QueryMethods::WhereChain.prepend BabySqueel::ActiveRecord::WhereChain
  ActiveRecord::Associations::JoinDependency.prepend BabySqueel::ActiveRecord::JoinDependency
  ActiveRecord::Associations::JoinDependency::JoinAssociation.prepend BabySqueel::ActiveRecord::JoinAssociation
end
