require "shared_examples/table"

describe BabySqueel::DSL do
  subject(:dsl) { create_dsl Post }

  it_behaves_like "a table" do
    let(:table) { dsl }
  end

  it "has no outer join, only an association does" do
    expect { dsl.outer }.to raise_error(BabySqueel::Error, /no column or association named 'outer'/)
  end

  describe "#find_alias" do
    it "resolves the tables Active Record's own join sources use" do
      relation = Post.joins(:author, comments: :author).left_joins(parent: :author)
      chains = [
        [create_association(Post, :author)],
        [create_association(Post, :comments), create_association(Comment, :author)],
        [create_association(Post, :parent)]
      ]
      resolved = chains.map { |chain| create_dsl(relation).find_alias(chain).name }

      join_sources = relation.arel.join_sources.map { |join| join.left.name }

      expect(resolved).to eq(%w[authors authors_comments parents_posts])
      expect(join_sources).to include(*resolved)
    end
  end

  describe "#_joins" do
    subject { dsl._joins([association]) }

    context "when inner joining" do
      let(:association) { create_association(Author, :posts) }
      specify { is_expected.to eq(posts: {}) }
    end

    context "when outer joining" do
      let(:association) { create_association(Author, :posts).outer }
      specify { is_expected.to eq(BabySqueel::Join.new(:posts, true, nil) => {}) }
    end

    context "when outer joining below an inner join" do
      subject { dsl._joins([create_association(Author, :posts), create_association(Post, :comments).outer]) }
      specify { is_expected.to eq(posts: { BabySqueel::Join.new(:comments, true, nil) => {} }) }
    end

    context "when not joining" do
      subject { dsl._joins }
      specify { is_expected.to eq(nil) }
    end
  end

  describe "#evaluate" do
    context "when an arity is given" do
      it "yields itself" do
        dsl.evaluate do |table|
          expect(table).to be_a(BabySqueel::DSL)
        end
      end

      it "does not change self" do
        this = self
        that = nil
        dsl.evaluate { |_t| that = self }
        expect(that).to equal(this)
      end
    end

    context "when no arity is given" do
      it "changes self" do
        this = self
        that = nil
        dsl.evaluate { that = self }
        expect(that).not_to equal(this)
      end

      it "resolves attributes without a receiver" do
        resolution = nil
        dsl.evaluate { resolution = title }
        expect(resolution).to be_an(Arel::Attributes::Attribute)
      end
    end
  end
end
