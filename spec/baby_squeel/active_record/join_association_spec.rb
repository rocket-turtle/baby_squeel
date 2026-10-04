describe ActiveRecord::Associations::JoinDependency::JoinAssociation, :join_dependency do
  let(:reflection) { Picture.reflect_on_association(:imageable) }
  let(:join_association) do
    join = new_join(:imageable, Arel::Nodes::OuterJoin, Post)
    new_join_dependency(Picture, join => {}).send(:join_root).children.first
  end

  it "joins the given class for a polymorphic reflection" do
    expect(join_association.reflection.klass).to eq(Post)
    expect(join_association.base_klass).to eq(Post)
  end

  it "carries the join type of the key" do
    expect(join_association.join_type).to eq(Arel::Nodes::OuterJoin)
  end

  it "is an inner join when built by Active Record" do
    plain = new_join_dependency(Post, :author).send(:join_root).children.first

    expect(plain.join_type).to eq(Arel::Nodes::InnerJoin)
  end

  it "leaves the original reflection intact for thread safety" do
    join_association

    expect(reflection.instance_variable_get(:@klass)).to be_nil
    expect(reflection).to be_polymorphic
  end

  it "keeps the reflection polymorphic" do
    expect(join_association.reflection).to be_polymorphic
  end
end
