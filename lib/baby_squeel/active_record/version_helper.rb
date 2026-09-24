module BabySqueel
  module ActiveRecord
    # The single place for Active Record version branches. Keeping them
    # together makes them easy to find and drop once support for a version
    # ends.
    class VersionHelper
      # Active Record 8.1 reports associations declared with deprecated: true
      # when they are joined.
      def self.deprecated_associations?
        defined?(::ActiveRecord::Associations::Deprecation) ? true : false
      end
    end
  end
end
