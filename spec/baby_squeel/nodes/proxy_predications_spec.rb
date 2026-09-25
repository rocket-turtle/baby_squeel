describe BabySqueel::Nodes::Proxy do
  let(:attribute) do
    BabySqueel::Nodes::Attribute.new(
      create_table(Post),
      :id
    )
  end

  describe "a wrapped binary node" do
    subject(:node) { attribute.eq(1) }

    it "creates the right SQL" do
      is_expected.to produce_sql('"posts"."id" = 1')
    end

    it "can be aliased" do
      expect(node.as("jawn")).to produce_sql('"posts"."id" = 1 AS jawn')
    end
  end

  describe "a wrapped grouping node" do
    subject(:node) { attribute.eq(1).or(attribute.eq(2)) }

    it "can be aliased" do
      expect(node.as("jawn")).to produce_sql('("posts"."id" = 1 OR "posts"."id" = 2) AS jawn')
    end

    it "can be ordered" do
      expect(node.desc).to produce_sql('("posts"."id" = 1 OR "posts"."id" = 2) DESC')
    end
  end
end
