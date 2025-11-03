require 'baby_squeel/dsl'

module BabySqueel
  module ActiveRecord
    class VersionHelper
      # Example
      #   BabySqueel::ActiveRecord::VersionHelper.at_least_8_1?
      #
      # def self.at_least_8_1?
      #   ::ActiveRecord::VERSION::MAJOR > 8 ||
      #     ::ActiveRecord::VERSION::MAJOR == 8 && ::ActiveRecord::VERSION::MINOR >= 1
      # end
    end
  end
end
