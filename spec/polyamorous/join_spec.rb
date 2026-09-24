module Polyamorous
  describe Join, :polyamorous do
    it "equals a join with the same name, type and class" do
      expect(new_join(:articles, OuterJoin, Post)).to eq(new_join(:articles, OuterJoin, Post))
      expect(new_join(:articles, OuterJoin)).not_to eq(new_join(:articles, InnerJoin))
      expect(new_join(:articles, OuterJoin, Post)).not_to eq(new_join(:articles, OuterJoin, Author))
    end

    it "dedupes as a hash key" do
      tree = { new_join(:articles, OuterJoin) => {} }

      expect(tree[new_join(:articles, OuterJoin)]).to eq({})
    end
  end
end
