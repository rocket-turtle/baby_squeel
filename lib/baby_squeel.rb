require 'active_record'
require 'active_record/relation'
require 'polyamorous/polyamorous'
require 'baby_squeel/version'
require 'baby_squeel/errors'

module BabySqueel
end

ActiveSupport.on_load :active_record do
  require 'baby_squeel/active_record/base'
  require 'baby_squeel/active_record/query_methods'
  require 'baby_squeel/active_record/where_chain'

  ::ActiveRecord::Base.extend BabySqueel::ActiveRecord::Base
  ::ActiveRecord::Relation.prepend BabySqueel::ActiveRecord::QueryMethods
  ::ActiveRecord::QueryMethods::WhereChain.prepend BabySqueel::ActiveRecord::WhereChain
end
