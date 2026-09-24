module Matchers
  # Compares normalized SQL for equality. RSpec's Match matcher would fall
  # back to String#match, which reads the expected SQL as a regular
  # expression and accepts any SQL that merely contains it.
  class MatchFormatted < RSpec::Matchers::BuiltIn::Eq
    def initialize(expected, formatter)
      @formatter = formatter
      super(@formatter.normalize(expected))
    end

    def matches?(actual)
      super(@formatter.normalize(actual))
    end

    def expected_formatted
      @formatter.call(@expected)
    end

    def actual_formatted
      @formatter.call(@actual)
    end
  end
end
