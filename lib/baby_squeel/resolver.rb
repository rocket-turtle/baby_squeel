module BabySqueel
  class Resolver
    def initialize(table, strategies)
      @table       = table
      @strategies  = strategies
    end

    # Try to resolve the method_missing. If we fail to resolve, there are
    # two outcomes:
    #
    # If any of the configured strategies accept argument signature provided,
    # raise an error. This means we failed to resolve the name. (ex. invalid
    # column name)
    #
    # Otherwise, a nil return valid indicates that argument signature was not
    # valid for any of the configured strategies. This case should be treated
    # as a NoMethodError.
    def resolve!(name, *args)
      return nil if block_given? || args.present?

      strategy = @strategies.find { |strategy| valid_name?(strategy, name) }
      if strategy.nil?
        raise NotFoundError.new(@table._scope.model_name, name, @strategies)
      end

      build(strategy, name)
    end

    # Used to determine if a table can respond_to? a method.
    def resolves?(name)
      @strategies.any? { |strategy| valid_name?(strategy, name) }
    end

    private

    def build(strategy, name)
      case strategy
      when :association
        @table.association(name)
      when :column, :attribute
        @table[name]
      end
    end

    def valid_name?(strategy, name)
      case strategy
      when :column
        @table._scope.column_names.include?(name.to_s)
      when :association
        !@table._scope.reflect_on_association(name).nil?
      when :attribute
        true
      end
    end
  end
end
