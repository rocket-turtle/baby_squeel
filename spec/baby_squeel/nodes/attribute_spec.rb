describe BabySqueel::Nodes::Attribute do
  subject(:attribute) do
    described_class.new(
      create_relation(Post),
      :id
    )
  end

  describe "#in" do
    it "doesnt break existing in behavior" do
      expect(attribute.in([1, 2])).to produce_sql('"posts"."id" IN (1, 2)')
    end

    it "returns a BabySqueel node" do
      relation = Post.select(:id)
      expect(attribute.in(relation)).to respond_to(:_arel)
    end

    it "keeps the bind parameters of the relation" do
      relation = Post.where.has { author_id.in Author.where(name: "Ray").select(:id) }
      _sql, binds = Post.connection.send(:to_sql_and_binds, relation.arel)

      expect(binds.map(&:value)).to eq(["Ray"])
    end

    it "applies eager loading to the relation" do
      subquery = Author.includes(:posts).where(posts: { title: "x" }).select(:id)
      relation = Post.where.has { author_id.in subquery }

      expect(relation.to_sql).to eq(Post.where(author_id: subquery).to_sql)
      expect(relation.to_sql).to include('LEFT OUTER JOIN "posts"')
    end

    it "selects the primary key when the relation selects nothing" do
      subquery = Author.where(name: "x")
      relation = Post.where.has { author_id.in subquery }

      expect(relation.to_sql).to eq(Post.where(author_id: subquery).to_sql)
      expect(relation.to_sql).to include('IN (SELECT "authors"."id" FROM "authors"')
    end
  end

  describe "#not_in" do
    it "doesnt break existing not_in behavior" do
      expect(attribute.not_in([1, 2])).to produce_sql('"posts"."id" NOT IN (1, 2)')
    end

    it "returns a BabySqueel node" do
      relation = Post.select(:id)
      expect(attribute.not_in(relation)).to respond_to(:_arel)
    end

    it "applies eager loading to the relation" do
      subquery = Author.includes(:posts).where(posts: { title: "x" }).select(:id)
      relation = Post.where.has { author_id.not_in subquery }

      expect(relation.to_sql).to include('NOT IN (SELECT "authors"."id" FROM "authors" LEFT OUTER JOIN "posts"')
    end

    it "selects the primary key when the relation selects nothing" do
      relation = Post.where.has { author_id.not_in Author.where(name: "x") }

      expect(relation.to_sql).to include('NOT IN (SELECT "authors"."id" FROM "authors" WHERE')
    end

    # not_in takes the IN node apart, so it depends on the handler returning
    # an Arel::Nodes::In whose left is the attribute and whose right is the
    # select statement of the relation.
    it "builds on the node the RelationHandler returns" do
      handler = ActiveRecord::PredicateBuilder::RelationHandler.new
      node = handler.call(Post.arel_table[:author_id], Author.select(:id))

      expect(node).to be_an_instance_of(Arel::Nodes::In)
      expect(node.left).to eq(Post.arel_table[:author_id])
      expect(node.right).to be_a(Arel::Nodes::SelectStatement)
    end
  end
end
