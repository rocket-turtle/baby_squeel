require 'spec_helper'

RSpec.describe BabySqueel::Resolver do
  let(:table)       { create_table Post.arel_table }
  let(:dsl)         { create_dsl Post }
  let(:relation)    { create_relation Post }
  let(:association) { create_association Post, :author }

  let :valid_cases do
    [
      [table,       :attribute,   :foo,      []],
      [relation,    :column,      :title,    []],
      [relation,    :association, :author,   []],
      [association, :column,      :name,     []],
      [association, :association, :posts,    []],
      [dsl,         :column,      :title,    []],
      [dsl,         :association, :author,   []],
    ]
  end

  let :wrong_args_cases do
    [
      [table,       :attribute,   :foo,      [1]],
      [relation,    :column,      :title,    [1]],
      [relation,    :association, :author,   [1]],
      [association, :column,      :name,     [1]],
      [association, :association, :posts,    [1]],
      [dsl,         :column,      :title,    [1]],
      [dsl,         :association, :author,   [1]],
    ]
  end

  let :invalid_name_cases do
    [
      [relation,    :column,      :missing,  []],
      [relation,    :association, :missing,  []],
      [association, :column,      :missing,  []],
      [association, :association, :missing,  []],
      [dsl,         :column,      :missing,  []],
      [dsl,         :association, :missing,  []]
    ]
  end

  describe '#resolve!' do
    it 'handles valid resolutions' do
      valid_cases.each do |node, strategy, name, args|
        msg = "resolve! #{name} using #{strategy}"
        resolver = described_class.new(node, [strategy])
        expect(resolver.resolve!(name, *args)).not_to be_nil, msg
      end
    end

    it 'is nil for the wrong number of arguments' do
      wrong_args_cases.each do |node, strategy, name, args|
        msg = "does not resovle! #{name} using #{strategy}"
        resolver = described_class.new(node, [strategy])
        expect(resolver.resolve!(name, *args)).to be_nil, msg
      end
    end

    it 'raises for the correct number of arguments, but invalid name' do
      invalid_name_cases.each do |node, strategy, name, args|
        msg = "raises NotFoundError for #{name} using #{strategy}"
        resolver = described_class.new(node, [strategy])
        expect {
          resolver.resolve!(name, *args)
        }.to raise_error(BabySqueel::NotFoundError)
      end
    end
  end

  describe '#resolves?' do
    it 'is true for valid name' do
      cases = valid_cases + wrong_args_cases

      cases.each do |node, strategy, name, _args|
        msg = "Could not resolves? #{name} using #{strategy}"
        resolver = described_class.new(node, [strategy])
        expect(resolver.resolves?(name)).to eq(true), msg
      end
    end

    it 'is false for invalid names' do
      invalid_name_cases.each do |node, strategy, name, _args|
        msg = "Should not have resolves? #{name} using #{strategy}"
        resolver = described_class.new(node, [strategy])
        expect(resolver.resolves?(name)).to eq(false), msg
      end
    end
  end
end
