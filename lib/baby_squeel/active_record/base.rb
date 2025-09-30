require 'baby_squeel/dsl'

module BabySqueel
  module ActiveRecord
    module Base
      delegate :joining,
               :selecting,
               :ordering,
               :reordering,
               :grouping,
               :when_having,
               :plucking,
               :averaging,
               :counting,
               :maximizing,
               :minimizing,
               :summing,
               to: :all
    end
  end
end
