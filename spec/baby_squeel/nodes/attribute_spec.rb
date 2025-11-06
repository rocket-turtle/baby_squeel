require 'spec_helper'
require 'baby_squeel/nodes'
require 'baby_squeel/table'

describe BabySqueel::Nodes::Attribute do
  subject(:attribute) {
    described_class.new(
      create_relation(Post),
      :id
    )
  }

  describe '#in' do
    it 'doesnt break existing in behavior' do
      expect(attribute.in([1, 2])).to produce_sql('"posts"."id" IN (1, 2)')
    end

    it 'returns a BabySqueel node' do
      relation = Post.select(:id)
      expect(attribute.in(relation)).to respond_to(:_arel)
    end
  end

  describe '#not_in' do
    it 'doesnt break existing not_in behavior' do
      expect(attribute.not_in([1, 2])).to produce_sql('"posts"."id" NOT IN (1, 2)')
    end

    it 'returns a BabySqueel node' do
      relation = Post.select(:id)
      expect(attribute.not_in(relation)).to respond_to(:_arel)
    end
  end
end
