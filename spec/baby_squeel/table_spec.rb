require "shared_examples/table"

describe BabySqueel::Table do
  subject(:table) { create_table :posts }

  include_examples "a table"

  describe "#_arel" do
    subject { table._arel([association]) }

    context "when inner joining" do
      let(:association) { create_association(Author, :posts) }
      specify { is_expected.to eq(posts: {}) }
    end

    context "when outer joining" do
      let(:association) { create_association(Author, :posts).outer }
      specify { is_expected.to eq(Polyamorous::Join.new(:posts, Arel::Nodes::OuterJoin) => {}) }
    end

    context "when outer joining below an inner join" do
      subject { table._arel([create_association(Author, :posts), create_association(Post, :comments).outer]) }
      specify { is_expected.to eq(posts: { Polyamorous::Join.new(:comments, Arel::Nodes::OuterJoin) => {} }) }
    end

    context "when not joining" do
      subject { table._arel }
      specify { is_expected.to eq(nil) }
    end
  end
end
