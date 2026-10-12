describe ActiveRecord::Associations::JoinDependency do
  it "leaves the original reflection intact for thread safety" do
    reflection = Picture.reflect_on_association(:imageable)
    new_join_dependency(Picture, new_join(:imageable, Arel::Nodes::OuterJoin, Post) => {})

    expect(reflection.instance_variable_get(:@klass)).to be_nil
    expect(reflection).to be_polymorphic
  end
end
