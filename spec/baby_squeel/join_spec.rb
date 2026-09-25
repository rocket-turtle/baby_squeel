describe BabySqueel::Join, :join_dependency do
  it "equals a join with the same name, type and class" do
    outer_post = new_join(:articles, Arel::Nodes::OuterJoin, Post)

    expect(outer_post).to eq(new_join(:articles, Arel::Nodes::OuterJoin, Post))
    expect(outer_post).not_to eq(new_join(:articles, Arel::Nodes::InnerJoin, Post))
    expect(outer_post).not_to eq(new_join(:articles, Arel::Nodes::OuterJoin, Author))
  end

  it "dedupes as a hash key" do
    tree = { new_join(:articles, Arel::Nodes::OuterJoin) => {} }

    expect(tree[new_join(:articles, Arel::Nodes::OuterJoin)]).to eq({})
  end
end
