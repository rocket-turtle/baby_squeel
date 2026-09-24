module Polyamorous
  module JoinAssociationExtensions
    include SwappingReflectionClass

    attr_reader :join_type

    def initialize(reflection, children, polymorphic_class = nil, join_type = Arel::Nodes::InnerJoin)
      @join_type = join_type
      if polymorphic_class && polymorphic_class < ::ActiveRecord::Base
        swapping_reflection_klass(reflection, polymorphic_class) do |reflection|
          super(reflection, children)
        end
      else
        super(reflection, children)
      end
    end
  end
end
