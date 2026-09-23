module Matchers
  module SQLFormatter
    INDENT = "\n        ".freeze

    KEYWORDS = [
      "WHERE",
      "ORDER BY",
      "GROUP BY",
      "HAVING",
      "INNER JOIN",
      "LEFT OUTER JOIN",
      "LIMIT"
    ].freeze

    def self.call(value)
      normalize(value)
        .gsub(/#{KEYWORDS.join('|')}/) { |m| "#{INDENT}#{m.strip}" }
        .prepend(INDENT)
    end

    def self.normalize(value)
      if value.kind_of? Regexp
        value
      elsif value.kind_of? String
        value.squish.gsub("( ", "(").gsub(" )", ")")
      elsif value.respond_to?(:to_sql)
        normalize(value.to_sql)
      else
        raise ArgumentError, "cannot normalize #{value.class}"
      end
    end
  end
end
