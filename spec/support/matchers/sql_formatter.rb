module Matchers
  module SQLFormatter
    INDENT = "\n        "

    KEYWORDS = %w(
      WHERE
      ORDER\ BY
      GROUP\ BY
      HAVING
      INNER\ JOIN
      LEFT\ OUTER\ JOIN
      LIMIT
    )

    def self.call(value)
      normalize(value)
        .gsub(/#{KEYWORDS.join('|')}/) { |m| "#{INDENT}#{m.strip}" }
        .prepend(INDENT)
    end

    def self.normalize(value)
      if value.kind_of? Regexp
        value
      elsif value.kind_of? String
        value.squish.gsub(/\( /, "(").gsub(/ \)/, ")")
      elsif value.respond_to?(:to_sql)
        normalize(value.to_sql)
      end
    end
  end
end
