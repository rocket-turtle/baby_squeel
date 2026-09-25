module BabySqueel
  # A key in the association tree Active Record's JoinDependency walks. Where
  # a plain key is the association name, a Join also carries the join type
  # and the class a polymorphic association is joined with. As a Data value
  # it compares by content, so Active Record dedupes equal joins like names.
  Join = Data.define(:name, :type, :klass) do
    def initialize(name:, type: Arel::Nodes::InnerJoin, klass: nil) = super
  end
end
