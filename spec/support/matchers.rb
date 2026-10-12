# Compares normalized SQL for equality, never as a pattern. On failure each
# clause starts a line, so the diff points at the join or condition.
RSpec::Matchers.define :produce_sql do |expected|
  normalize = lambda do |sql|
    sql = sql.to_sql if sql.respond_to?(:to_sql)
    raise ArgumentError, "cannot normalize #{sql.class}" unless sql.is_a?(String)

    sql.squish.gsub("( ", "(").gsub(" )", ")")
  end
  clause = / (?=INNER JOIN|LEFT OUTER JOIN|WHERE|ORDER BY|GROUP BY|HAVING|LIMIT)/
  format = ->(sql) { normalize.call(sql).gsub(clause, "\n") }

  match { |actual| normalize.call(actual) == normalize.call(expected) }

  diffable

  define_method(:expected) { format.call(super()) }
  define_method(:actual) { format.call(super()) }
end
