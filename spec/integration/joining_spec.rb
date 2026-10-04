describe "#joining" do
  context "when joining implicitly" do
    it "merges bind values" do
      relation = Post.joining { ugly_author_comments }

      expect(relation).to produce_sql(Post.joins(:ugly_author_comments))
    end

    it "inner joins" do
      relation = Post.joining { author }

      expect(relation).to produce_sql(Post.joins(:author))
    end

    context "outer joins" do
      it "single" do
        relation = Post.joining { author.outer }

        expect(relation).to produce_sql(Post.left_joins(:author))
      end

      it "multi" do
        relation = Post.joining { parent.outer }.joining { author.outer }

        expect(relation).to produce_sql(Post.joining { [parent.outer, author.outer] })
        expect(relation).to produce_sql(Post.left_joins(:parent).left_joins(:author))
        expect(relation).to produce_sql(Post.joining { parent.outer }.left_joins(:author))

        # The order is different left_joins are at the end
        relation = Post.joining { [author.outer, parent.outer] }
        expect(relation).to produce_sql(Post.left_joins(:parent).joining { author.outer })
      end
    end

    it "correctly aliases when joining the same table twice" do
      relation = Post.joining { [author.outer, parent.outer.author.outer] }
      relation = relation.where.has do
        author.outer.name.eq("Rick").or(parent.outer.author.outer.name.eq("Flair"))
      end

      active_record = Post.left_joins(:author, parent: :author).where(
        Author.arel_table[:name].eq("Rick").or(Author.arel_table.alias("authors_posts")[:name].eq("Flair"))
      )
      expect(relation).to produce_sql(active_record)
    end

    describe "polymorphism" do
      it "inner joins" do
        relation = Picture.joining { imageable.of(Post) }

        expect(relation).to match_sql_snapshot
      end

      it "outer joins" do
        relation = Picture.joining { imageable.of(Post).outer }

        expect(relation).to match_sql_snapshot
      end

      it "compares the type column with the polymorphic name of a subclass" do
        relation = Picture.joining { imageable.of(UglyAuthor) }

        expect(relation.to_sql).to include(%("pictures"."imageable_type" = 'Author'))
        # Active Record 8.0 quotes a SQLite boolean as 1, 8.1 as TRUE
        expect(relation.to_sql).to match(/"authors"\."ugly" = (TRUE|1) AND/)
      end

      it "double polymorphic joining" do
        join_scope = Picture.joining { [imageable.of(Author), imageable.of(Post)] }
        relation = join_scope.where.has do
          imageable.of(Author).name.eq("NameOfTheAuthor").or(imageable.of(Post).title.eq("NameOfThePost"))
        end

        expect(relation).to match_sql_snapshot
      end
    end

    describe "habtm" do
      it "inner joins" do
        relation = ResearchPaper.joins(:authors).where.has { authors.name.eq("Alex") }

        expect(relation).to produce_sql(ResearchPaper.joins(:authors).where(authors: { name: "Alex" }))
      end
    end

    describe "nested joins" do
      it "inner joins" do
        relation = Post.joining { author.comments }

        expect(relation).to produce_sql(Post.joins(author: :comments))
      end

      it "outer joins everything below an outer join, like Active Record" do
        relation = Post.joining { author.outer.comments }

        expect(relation).to produce_sql(Post.left_joins(author: :comments))
      end

      it "handles polymorphism" do
        relation = Picture.joining { imageable.of(Post).comments }

        expect(relation).to match_sql_snapshot
      end

      it "outer joins at multiple levels" do
        relation = Post.joining { author.outer.comments.outer }

        expect(relation).to produce_sql(Post.left_joins(author: :comments))
      end

      it "outer joins only the specified associations" do
        relation = Post.joining { author.comments.outer }

        expect(relation).to produce_sql(Post.joins(:author).left_joins(author: :comments))
      end

      it "keeps the outer join when the association was used before" do
        relation = Post.joining do |post|
          author = post.author
          author.name
          author.outer.comments
        end

        expect(relation).to produce_sql(Post.joining { author.outer.comments })
      end

      it "joins back with a new alias" do
        baby_squeel = Post.joining { author.posts }
        active_record = Post.joins(author: :posts)

        expect(baby_squeel).to produce_sql(active_record)
      end

      it "prevents mutation of the original instance" do
        relation = Post.joining do
          author.posts # this should have absolutely no effect
          author
        end

        expect(relation).to produce_sql(Post.joins(:author))
      end

      it "joins a through association" do
        baby_squeel = Post.joining { author.posts.author_comments }
        active_record = Post.joins(author: { posts: :author_comments })
        expect(baby_squeel).to produce_sql(active_record)
      end

      it "joins a through association and then back again" do
        relation = Post.joining { author.posts.author_comments.outer.post.author_comments }
        active_record = Post.joins(author: :posts)
                            .left_joins(author: { posts: { author_comments: { post: :author_comments } } })

        expect(relation).to produce_sql(active_record)
      end
    end

    describe "duplicate prevention" do
      context "when given two DSL joins" do
        it "dedupes" do
          relation = Post.joining { author }.joining { author }
          expect(relation).to produce_sql(Post.joins(:author))
        end

        it "dedupes outer joins" do
          relation = Post.joining { author.outer }.joining { author.outer }

          expect(relation).to produce_sql(Post.left_joins(:author))
        end

        it "dedupes polymorphic joins" do
          relation = Picture.joining { imageable.of(Post) }.joining { imageable.of(Post) }

          expect(relation.to_sql.scan("JOIN").size).to eq(1)
        end

        it "dedupes incremental joins" do
          relation = Post.joining { author }.joining { author.posts }

          expect(relation).to produce_sql(Post.joins(author: :posts))
        end
      end

      context "when given a DSL join with an Active Record join" do
        it "dedupes" do
          relation = Post.joining { author }.joins(:author)
          expect(relation).to produce_sql(Post.joins(:author))
        end

        it "dedupes (in any order)" do
          relation = Post.joins(:author).joining { author }
          expect(relation).to produce_sql(Post.joins(:author))
        end

        it "dedupes through joins" do
          relation = Post.joins(author: { posts: :author_comments })
                         .joining { author.posts.author_comments.outer }

          # author and posts merge with the Active Record joins. author_comments
          # does not: Active Record joins it inner, the DSL outer, and those are
          # different keys in the join tree. So the through association and the
          # authors table it goes through are joined a second time, as outer
          # joins. The pending example below states what Active Record does.
          expect(relation).to match_sql_snapshot(variants: ["8.1", "8.2"])
        end

        it "dedupes an outer join against the inner join Active Record made" do
          pending "an outer join of an association that is already inner joined is added instead of merged"

          relation = Post.joins(author: { posts: :author_comments })
                         .joining { author.posts.author_comments.outer }
          active_record = Post.joins(author: { posts: :author_comments })
                              .left_joins(author: { posts: :author_comments })

          expect(relation).to produce_sql(active_record)
        end

        it "dedupes incremental outer joins" do
          relation = Post.joins(:author).joining { author.comments.outer }

          expect(relation).to produce_sql(Post.joins(:author).left_joins(author: :comments))
        end

        it "dedupes incremental outer joins (in any order)" do
          relation = Post.joining { author.comments.outer }.joins(:author)

          expect(relation).to produce_sql(Post.left_joins(author: :comments).joins(:author))
        end
      end

      context "when given a DSL join with an Arel join" do
        let(:arel_join) do
          Arel::Nodes::InnerJoin.new(
            Author.arel_table,
            Arel::Nodes::On.new(
              Post.arel_table[:author_id].eq(
                Author.arel_table[:id]
              )
            )
          )
        end

        it "does what Active Record would do" do
          baby_squeel = Post.joining { author }.joins(arel_join)
          active_record = Post.joins(:author).joins(arel_join)
          expect(baby_squeel).to produce_sql(active_record)
        end

        it "does what Active Record would do (in any order)" do
          baby_squeel = Post.joins(arel_join).joining { author }
          active_record = Post.joins(arel_join).joins(:author)
          expect(baby_squeel).to produce_sql(active_record)
        end
      end
    end

    it "joins the association of the merged model when merged into another model" do
      relation = Comment.joins(:post).merge(Post.joining { author.outer })

      expect(relation.to_sql).to eq(Comment.joins(:post).merge(Post.left_outer_joins(:author)).to_sql)
      expect(relation.to_sql).to include('LEFT OUTER JOIN "authors" ON "authors"."id" = "posts"."author_id"')
    end

    it "correctly identifies a table independently joined via separate associations" do
      relation = Post
      relation = relation.joining { [author, comments.author] }
      relation = relation.where.has do
        comments.author.name.eq("Bob")
      end

      expect(relation).to produce_sql(Post.joins(:author, comments: :author).where(authors_comments: { name: "Bob" }))
    end
  end
end
