require 'spec_helper'
require 'baby_squeel/nodes'
require 'baby_squeel/table'

describe BabySqueel::Nodes::Binary do
  let(:attribute) {
    BabySqueel::Nodes::Attribute.new(
      create_relation(Post),
      :id
    )
  }

  subject(:node) { attribute.eq(1) }

  describe '#to_sql' do
    it 'creates the right SQL' do
      is_expected.to produce_sql('"posts"."id" = 1')
    end
  end

  describe '#as' do
    it 'can be aliased' do
      expect(node.as('jawn')).to produce_sql('"posts"."id" = 1 AS jawn')
    end
  end
end
