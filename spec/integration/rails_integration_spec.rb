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

    expect(relation).to produce_sql(Author.joins(posts: :comments).where(comments: { body: "body" }))
  end

  it "left_joins" do
    sql = Post.left_joins(:parent, :author).to_sql

    # 8.1 writes AS before a table alias, 8.0 does not
    expect(sql).to match(/LEFT OUTER JOIN "posts" (AS )?"parents_posts" ON "parents_posts"."id" = "posts"."parent_id"/)
    expect(sql).to include('LEFT OUTER JOIN "authors" ON "authors"."id" = "posts"."author_id"')
  end

  it "joins includes" do
    relation = Post.joins(:author).includes(:author)

    expect(relation).to produce_sql(Post.joins(:author).eager_load(:author))
  end

  it "self joins and includes" do
    parent_post = Post.create!
    post = Post.create!(parent: parent_post)

    posts = Post.joins(:parent).includes(:parent, :child)
    db_post = posts.first

    expect(db_post).to eq(post)
    expect(post.child).to be_nil
    expect(post.parent).to eq(parent_post)
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
