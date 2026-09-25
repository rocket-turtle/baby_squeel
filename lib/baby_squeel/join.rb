module BabySqueel
  # A key in the association tree Active Record's JoinDependency walks. Where
  # a plain key is the association name, a Join also carries the join type
  # and the class a polymorphic association is joined with. Equal joins are
  # equal hash keys, so Active Record dedupes them like names.
  class Join
    attr_reader :name, :type, :klass

    # type is Arel::Nodes::InnerJoin or Arel::Nodes::OuterJoin, klass the
    # model a polymorphic association is joined with (nil otherwise).
    def initialize(name, type = Arel::Nodes::InnerJoin, klass = nil)
      @name = name
      @type = type
      @klass = klass
    end

    def hash
      [@name, @type, @klass].hash
    end

    def eql?(other)
      self.class == other.class &&
        name  == other.name &&
        type  == other.type &&
        klass == other.klass
    end

    alias_method :==, :eql?
  end
end
