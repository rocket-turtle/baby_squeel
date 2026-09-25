require "active_record"
require "baby_squeel/version"
require "baby_squeel/errors"

module BabySqueel
end

ActiveSupport.on_load :active_record do
  require "baby_squeel/active_record/base"
  require "baby_squeel/active_record/query_methods"
  require "baby_squeel/active_record/where_chain"
  require "baby_squeel/active_record/join_dependency"
  require "baby_squeel/active_record/join_association"
  require "baby_squeel/active_record/reflection"

  ActiveRecord::Base.extend BabySqueel::ActiveRecord::Base
  ActiveRecord::Relation.prepend BabySqueel::ActiveRecord::QueryMethods
  ActiveRecord::QueryMethods::WhereChain.prepend BabySqueel::ActiveRecord::WhereChain
  ActiveRecord::Associations::JoinDependency.prepend BabySqueel::ActiveRecord::JoinDependency
  ActiveRecord::Associations::JoinDependency::JoinAssociation.prepend BabySqueel::ActiveRecord::JoinAssociation
  ActiveRecord::Reflection::AbstractReflection.prepend BabySqueel::ActiveRecord::Reflection
end
