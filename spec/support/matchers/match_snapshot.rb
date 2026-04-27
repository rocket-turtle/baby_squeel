module Matchers
  class MatchSnapshot < RSpec::Matchers::BuiltIn::Eq
    def initialize(snapshot, formatter)
      @snapshot = snapshot
      @formatter = formatter
      super(@snapshot.read)
    end

    def matches?(actual)
      actual = @formatter.normalize(actual)

      if @snapshot.read && !ENV["UPDATE_SNAPSHOTS"]
        super(actual)
      else
        @snapshot.write(actual)
        true
      end
    end

    def expected_formatted
      @formatter.call(@expected)
    end

    def actual_formatted
      @formatter.call(@actual)
    end
  end
end
