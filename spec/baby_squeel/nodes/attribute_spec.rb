describe BabySqueel::Nodes::Attribute do
  subject(:attribute) do
    create_table(Post)[:id]
  end

  it "is the Arel attribute of the column, equal to Active Record's" do
    expect(attribute).to be_an_instance_of(Arel::Attributes::Attribute)
    expect(attribute).to eq(Post.arel_table[:id])
    expect(attribute.hash).to eq(Post.arel_table[:id].hash)
  end

  describe "#in" do
    it "doesnt break existing in behavior" do
      expect(attribute.in([1, 2])).to produce_sql('"posts"."id" IN (1, 2)')
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

    it "applies eager loading to the relation" do
      subquery = Author.includes(:posts).where(posts: { title: "x" }).select(:id)
      relation = Post.where.has { author_id.not_in subquery }

      expect(relation.to_sql).to include('NOT IN (SELECT "authors"."id" FROM "authors" LEFT OUTER JOIN "posts"')
    end

    it "selects the primary key when the relation selects nothing" do
      relation = Post.where.has { author_id.not_in Author.where(name: "x") }

      expect(relation.to_sql).to include('NOT IN (SELECT "authors"."id" FROM "authors" WHERE')
    end
  end
end
