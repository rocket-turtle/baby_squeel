require 'spec_helper'
require 'baby_squeel/nodes/node'

describe BabySqueel::Nodes::Node do
  subject(:node) {
    described_class.new(Post.arel_table[:id])
  }

  it 'extends any node with math' do
    expect((node + 5) * 5).to produce_sql('("posts"."id" + 5) * 5')
  end
end
