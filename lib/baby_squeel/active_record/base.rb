require 'baby_squeel/dsl'

module BabySqueel
  module ActiveRecord
    module Base
      delegate :joining,
               to: :all
    end
  end
end
