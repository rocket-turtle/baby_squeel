describe "#where.has" do
  it "wheres on an attribute" do
    relation = Post.where.has { title.eq("OJ Simpson") }

    expect(relation).to produce_sql(Post.where(title: "OJ Simpson"))
  end

  it "rejects an association in place of a condition" do
    message = "where.has got #<BabySqueel::Association author> instead of a condition"

    expect { Post.where.has { author } }.to raise_error(ArgumentError, message)
  end

  it "rejects an array of conditions" do
    expect { Post.where.has { [title.eq("x"), id.gt(1)] } }
      .to raise_error(ArgumentError, /where\.has got \[.*\] instead of a condition/)
  end

  it "resolves the alias of an association once per block" do
    expect(ActiveRecord::Associations::JoinDependency).to receive(:new).once.and_call_original

    Post.joins(:author).where.has { author.name.eq("x").and(author.age.gt(1)).and(author.id.lt(9)) }
  end

  it "unwraps nodes passed as arguments" do
    relation = Post.joins(:author).where.has { title.eq(author.name).and(id.in([parent_id, child_id])) }
    posts = Post.arel_table
    active_record = Post.joins(:author).where(
      posts[:title].eq(Author.arel_table[:name]).and(posts[:id].in([posts[:parent_id], posts[:child_id]]))
    )

    expect(relation).to produce_sql(active_record)
  end

  it "accepts nil" do
    relation = Post.where.has { nil }

    expect(relation).to produce_sql(Post.all)
  end

  it "wheres on associations" do
    relation = Post.joins(:author).where.has do
      author.name.eq("Yo Gotti")
    end

    expect(relation).to produce_sql(Post.joins(:author).where(authors: { name: "Yo Gotti" }))
  end

  it "wheres using operations" do
    relation = Post.where.has { (id + 1).eq(2) }

    expect(relation).to produce_sql(Post.where((Post.arel_table[:id] + 1).eq(2)))
  end

  it "wheres using complex conditions" do
    relation = Post.joins(:author).where.has do
      title.matches("Simp%").or(author.name.eq("meatloaf"))
    end

    expect(relation).to produce_sql(
      Post.joins(:author).where(Post.arel_table[:title].matches("Simp%").or(Author.arel_table[:name].eq("meatloaf")))
    )
  end

  it "wheres on deep associations" do
    relation = Post.joins(author: :comments).where.has do
      author.comments.id.gt(0)
    end

    expect(relation).to produce_sql(Post.joins(author: :comments).where(Comment.arel_table[:id].gt(0)))
  end

  it "wheres on an aliased association" do
    relation = Post.joins(author: :posts).where.has do
      author.posts.id.gt(0)
    end

    expect(relation).to produce_sql(Post.joins(author: :posts).where(Post.arel_table.alias("posts_authors")[:id].gt(0)))
  end

  it "wheres on an aliased association with through" do
    relation = Post.joins(:comments, :author_comments).where.has do
      author_comments.id.gt(0)
    end

    expect(relation).to produce_sql(
      Post.joins(:comments, :author_comments).where(Comment.arel_table.alias("author_comments_posts")[:id].gt(0))
    )
  end

  it "wheres on polymorphic associations" do
    relation = Picture.joining { imageable.of(Post) }.where.has do
      imageable.of(Post).title.matches("meatloaf")
    end

    expect(relation).to match_sql_snapshot
  end

  it "wheres on polymorphic associations outer join" do
    relation = Picture.joining { imageable.of(Post).outer }.where.has do
      imageable.of(Post).title.matches("meatloaf")
    end

    expect(relation).to match_sql_snapshot
  end

  it "wheres and correctly aliases" do
    relation = Post.joining { author.comments }
                   .where.has { author.comments.id.in [1, 2] }
                   .where.has { author.name.eq("Joe") }

    expect(relation).to produce_sql(
      Post.joins(author: :comments).where(comments: { id: [1, 2] }, authors: { name: "Joe" })
    )
  end

  it "wheres on an alias with outer join" do
    relation = Post.joining { author.comments.outer }
                   .where.has { author.comments.id.in [1, 2] }
                   .where.has { author.name.eq("Joe") }

    expect(relation).to produce_sql(
      Post.joins(:author).left_joins(author: :comments).where(comments: { id: [1, 2] }, authors: { name: "Joe" })
    )
  end

  it "wheres with an empty subquery" do
    relation = Post.where.has do
      author_id.in Author.none.select(:id)
    end

    expect(relation).to produce_sql(Post.where(author_id: Author.none.select(:id)))
  end

  it "wheres with an empty subquery and keeps values" do
    other = Author.joins(:posts)
                  .group(:id)
                  .select(:id)
                  .order(:id)
                  .none

    relation = Post.where.has { author_id.in other }

    expect(relation).to produce_sql(Post.where(author_id: other))
  end

  it "wheres with a not in subquery" do
    relation = Post.where.has do
      author_id.not_in Author.none.select(:id)
    end

    expect(relation).to produce_sql(Post.where.not(author_id: Author.none.select(:id)))
  end

  it "handles a hash" do
    bs = Post.where.has { { id: 1 } }
    ar = Post.where(id: 1)

    expect(bs.to_sql).to eq(ar.to_sql)
  end

  it "handles an empty hash" do
    bs = Post.where.has { {} }
    ar = Post.where({})

    expect(bs.to_sql).to eq(ar.to_sql)
  end
end

describe "#where_values_hash" do
  it "returns the same hash that Rails normally would" do
    bs = Author.where.has { id.eq(123) }
    ar = Author.where(id: 123)
    expect(bs.where_values_hash).to eq(ar.where_values_hash)
  end
end
