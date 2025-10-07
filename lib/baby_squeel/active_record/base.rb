require 'baby_squeel/dsl'

module BabySqueel
  module ActiveRecord
    module Base
      delegate :joining,
               :selecting,
               to: :all
    end
  end
end
