describe ActiveRecord::Associations::JoinDependency::JoinAssociation, :join_dependency do
  let(:join_dependency) { new_join_dependency(Picture, {}) }
  let(:reflection) { Picture.reflect_on_association(:imageable) }
  let(:parent) { join_dependency.send(:join_root) }
  let(:join_association) { new_join_association(reflection, parent.children, Post) }

  it "joins the given class for a polymorphic reflection" do
    expect(join_association.reflection.klass).to eq(Post)
    expect(join_association.base_klass).to eq(Post)
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
