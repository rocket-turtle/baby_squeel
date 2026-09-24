module Polyamorous
  class Join
    include TreeNode

    attr_reader :name, :type, :klass

    # type is Arel::Nodes::InnerJoin or Arel::Nodes::OuterJoin, klass the
    # model a polymorphic association is joined with (nil otherwise).
    def initialize(name, type = InnerJoin, klass = nil)
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

    def add_to_tree(hash)
      hash[self] ||= {}
    end
  end
end
