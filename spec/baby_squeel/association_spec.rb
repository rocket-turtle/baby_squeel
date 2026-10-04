require "shared_examples/table"

describe BabySqueel::Association do
  subject(:association) { create_association Author, :posts }
  let(:polymorph) { create_association Picture, :imageable }

  it_behaves_like "a table" do
    let(:table) { association }
  end

  describe "#of" do
    specify { expect(polymorph._scope).to be_nil }
    specify { expect(polymorph._table).to be_nil }
    specify { expect(polymorph._polymorphic_klass).to be_nil }
    specify { expect(polymorph.inspect).to eq("#<BabySqueel::Association imageable>") }

    it "assigns the _scope" do
      expect(polymorph.of(Post)._scope).to eq(Post)
    end

    it "assigns the _table" do
      expect(polymorph.of(Post)._table).to eq(Post.arel_table)
    end

    it "assigns the _polymorphic_klass" do
      expect(polymorph.of(Post)._polymorphic_klass).to eq(Post)
    end

    it "rejects anything but a model class" do
      expect { polymorph.of("Post") }.to raise_error(ArgumentError, /"Post" is not an Active Record model/)
      expect { polymorph.of(Post.new) }.to raise_error(ArgumentError)
    end

    it "throws a fit when the reflection is not polymorphic" do
      expect { association.of(Post) }.to raise_error(BabySqueel::Error, /'posts' is not a polymorphic association/)
    end
  end

  describe "#join_key" do
    it "is the name for an inner join" do
      expect(association.join_key).to eq(:posts)
    end

    it "is a Join for an outer join" do
      expect(association.outer.join_key).to eq(BabySqueel::Join.new(:posts, Arel::Nodes::OuterJoin))
    end

    it "is a Join with the class for a polymorphic association" do
      expect(polymorph.of(Post).join_key).to eq(BabySqueel::Join.new(:imageable, Arel::Nodes::InnerJoin, Post))
    end
  end

  describe "#method_missing" do
    it "raises when a polymorphic association is used without #of" do
      expect { polymorph.name }.to raise_error(BabySqueel::Error, /imageable\.of\(SomeModel\)/)
    end

    it "resolves once #of has named the class" do
      expect(polymorph.of(Author).name).to be_an(Arel::Attributes::Attribute)
    end
  end

  describe "#respond_to?" do
    it "does not resolve on a polymorphic association without #of" do
      expect(polymorph).not_to respond_to(:name)
      expect(polymorph.of(Author)).to respond_to(:name)
    end
  end

  describe "#_arel" do
    context "when implicitly joining" do
      context "when inner joining" do
        it "resolves to a hash" do
          expect(association._arel).to eq(posts: {})
        end
      end

      context "when outer joining" do
        it "resolves to a Join" do
          expect(association.outer._arel).to eq(BabySqueel::Join.new(:posts, Arel::Nodes::OuterJoin) => {})
        end
      end

      context "when joining polymorphic associations" do
        it "throws an error if the _polymorphic_klass has not been set" do
          expect { polymorph._arel }.to raise_error(BabySqueel::Error, /'imageable' is a polymorphic association/)
        end
      end
    end
  end

  describe "#find_alias" do
    it "finds the alias" do
      expect(association.find_alias.name).to eq("posts")
    end

    # Without `reconstruct_with_type_caster`, this would fail in Active Record 5.
    # See: https://github.com/rails/rails/pull/27994
    it "uses the correct type_caster" do
      view_count = association.find_alias[:view_count]
      expect(view_count.eq("5")).to produce_sql('"posts"."view_count" = 5')
    end
  end
end
