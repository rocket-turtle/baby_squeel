describe "#joining checks an association like Active Record" do
  it "rejects an instance dependent scope" do
    expect { Post.joins(:instance_comments).to_sql }.to raise_error(ArgumentError, /instance dependent/)
    expect { Post.joining { instance_comments.outer }.to_sql }.to raise_error(ArgumentError, /instance dependent/)
  end

  it "rejects an inverse_of that names no association" do
    expect { Post.joins(:misdeclared_comments).to_sql }.to raise_error(ActiveRecord::InverseOfAssociationNotFoundError)
    expect { Post.joining { misdeclared_comments.outer }.to_sql }
      .to raise_error(ActiveRecord::InverseOfAssociationNotFoundError)
  end
end
