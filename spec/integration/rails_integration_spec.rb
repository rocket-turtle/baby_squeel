describe "test that plain rails still works" do
  context "with a deprecated association", if: BabySqueel::ActiveRecord::VersionHelper.deprecated_associations? do
    around do |example|
      mode = ActiveRecord::Associations::Deprecation.mode
      ActiveRecord::Associations::Deprecation.mode = :raise
      example.run
    ensure
      ActiveRecord::Associations::Deprecation.mode = mode
    end

    it "reports the association when Active Record joins it" do
      expect { Post.joins(:deprecated_comments).to_sql }.to raise_error(ActiveRecord::DeprecatedAssociationError)
    end

    it "reports the association when BabySqueel joins it" do
      expect { Post.joining { deprecated_comments }.to_sql }.to raise_error(ActiveRecord::DeprecatedAssociationError)
    end

    it "reports the association when BabySqueel outer joins it" do
      expect { Post.joining { deprecated_comments.outer }.to_sql }
        .to raise_error(ActiveRecord::DeprecatedAssociationError)
    end
  end

  it "joins and merge" do
    relation = Author.joins(:posts).merge(Post.joins(:comments).merge(Comment.where(body: "body")))

    expect(relation).to match_sql_snapshot
  end

  it "left_joins" do
    relation = Post.left_joins(:parent, :author)

    expect(relation).to match_sql_snapshot(variants: ["8.1", "8.2"])
  end

  it "joins includes" do
    relation = Post.joins(:author).includes(:author).to_sql

    expect(relation).to match_sql_snapshot
  end

  it "joins an association with a nil value" do
    expect(Post.joins(author: nil).to_sql).to include("INNER JOIN")
  end

  it "does not alias a table named by references" do
    sql = Post.eager_load(:author).references("author").to_sql

    expect(sql).to include('LEFT OUTER JOIN "authors" ON')
    expect(sql).not_to include('AS "author"')
  end
end
