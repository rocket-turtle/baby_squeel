module Matchers
  class MatchSnapshot < RSpec::Matchers::BuiltIn::Eq
    def initialize(snapshot, formatter)
      @snapshot = snapshot
      @formatter = formatter
      super(@snapshot.read)
    end

    def matches?(actual)
      actual = @formatter.normalize(actual)

      if ENV["UPDATE_SNAPSHOTS"]
        @snapshot.write(actual)
        true
      elsif @snapshot.read.nil?
        # Recording on the fly would let a renamed example assert nothing and
        # still report green in every run from then on.
        raise "No snapshot for #{@snapshot.name.inspect}. Record it with UPDATE_SNAPSHOTS=1."
      else
        super
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
