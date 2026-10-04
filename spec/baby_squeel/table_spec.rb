require "shared_examples/table"

describe BabySqueel::Table do
  subject(:table) { create_table Post }

  include_examples "a table"

  describe "#find_alias" do
    it "resolves the tables Active Record's own join sources use" do
      relation = Post.joins(:author, comments: :author).left_joins(parent: :author)
      chains = [
        [create_association(Post, :author)],
        [create_association(Post, :comments), create_association(Comment, :author)],
        [create_association(Post, :parent)]
      ]
      resolved = chains.map { |chain| create_table(relation).find_alias(chain).name }

      join_sources = relation.arel.join_sources.map { |join| join.left.name }

      expect(resolved).to eq(%w[authors authors_comments parents_posts])
      expect(join_sources).to include(*resolved)
    end
  end

  describe "#_arel" do
    subject { table._arel([association]) }

    context "when inner joining" do
      let(:association) { create_association(Author, :posts) }
      specify { is_expected.to eq(posts: {}) }
    end

    context "when outer joining" do
      let(:association) { create_association(Author, :posts).outer }
      specify { is_expected.to eq(BabySqueel::Join.new(:posts, Arel::Nodes::OuterJoin) => {}) }
    end

    context "when outer joining below an inner join" do
      subject { table._arel([create_association(Author, :posts), create_association(Post, :comments).outer]) }
      specify { is_expected.to eq(posts: { BabySqueel::Join.new(:comments, Arel::Nodes::OuterJoin) => {} }) }
    end

    context "when not joining" do
      subject { table._arel }
      specify { is_expected.to eq(nil) }
    end
  end
end
