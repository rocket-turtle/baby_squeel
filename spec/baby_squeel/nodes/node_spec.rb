require 'spec_helper'
require 'baby_squeel/nodes/node'

describe BabySqueel::Nodes::Node do
  subject(:node) {
    described_class.new(Post.arel_table[:id])
  }

  describe 'included modules' do
    subject { described_class.ancestors }
    specify { is_expected.to include(BabySqueel::Operators::Equality) }
    specify { is_expected.to include(BabySqueel::Operators::Generic) }
  end

  it 'extends any node with math' do
    expect((node + 5) * 5).to produce_sql('("posts"."id" + 5) * 5')
  end
end
