This is a fork of [baby_squeel](https://github.com/rzane/baby_squeel) kept compatible with current Active Record for one application. Features that application does not use are removed without deprecation. It is published in case others find the commits useful; using it elsewhere is not recommended.

# BabySqueel 🐷

A Squeel-like query DSL for Active Record with a minimum of monkeypatching: two methods, `joining` and `where.has`, and the Active Record hooks they need.

## Introduction

With Active Record, you might write something like this:

```ruby
Post.where('created_at >= ?', 2.weeks.ago)
```

But then someone tells you, "Hey, you should use Arel!". So you convert your query to use Arel:

```ruby
Post.where(Post.arel_table[:created_at].gteq(2.weeks.ago))
```

Well, that's great, but it's also pretty verbose. Why don't you give BabySqueel a try:

```ruby
Post.where.has { created_at.gteq(2.weeks.ago) }
```

#### Quick note

BabySqueel's blocks use `instance_eval`, which means you won't have access to your instance variables or methods. Don't worry, there's a really easy solution. Just give arity to the block:

```ruby
Post.where.has { |post| post.created_at.gteq(2.weeks.ago) }
```

A column whose name is also a Ruby method, such as `hash`, `display` or `format`, or one of the DSL's own methods, `outer`, `of`, `association`, `evaluate`, `find_alias`, `join_key`, cannot be resolved by name: Ruby finds the method first. Use `[]` for those columns:

```ruby
Post.where.has { self[:hash].eq('abc') }
Post.where.has { |post| post[:hash].eq('abc') }
```

## Usage

Okay, so we have some models:

```ruby
class Post < ActiveRecord::Base
  belongs_to :author
  has_many :comments
end

class Author < ActiveRecord::Base
  has_many :posts
  has_many :comments, through: :posts
end

class Comment < ActiveRecord::Base
  belongs_to :post
end
```

The SQL in the comments is as Active Record 8.0 renders it; 8.1 writes `AS` before a table alias.

##### Wheres

```ruby
Post.where.has { title.eq('My Post') }
# SELECT "posts".* FROM "posts"
# WHERE "posts"."title" = 'My Post'

Post.where.has { title.matches('My P%') }
# SELECT "posts".* FROM "posts"
# WHERE "posts"."title" LIKE 'My P%'

Author.where.has { name.matches('Ray%').and(id.lt(5)).or(name.lower.matches('zane%').and(id.gt(100))) }
# SELECT "authors".* FROM "authors"
# WHERE ("authors"."name" LIKE 'Ray%' AND "authors"."id" < 5 OR LOWER("authors"."name") LIKE 'zane%' AND "authors"."id" > 100)

Post.joins(:author).where.has { author.name.eq('Ray') }
# SELECT "posts".* FROM "posts"
# INNER JOIN "authors" ON "authors"."id" = "posts"."author_id"
# WHERE "authors"."name" = 'Ray'

Post.joins(author: :posts).where.has { author.posts.title.matches('%fun%') }
# SELECT "posts".* FROM "posts"
# INNER JOIN "authors" ON "authors"."id" = "posts"."author_id"
# INNER JOIN "posts" "posts_authors" ON "posts_authors"."author_id" = "authors"."id"
# WHERE "posts_authors"."title" LIKE '%fun%'
```

A referenced association has to be joined, as in the examples above. `includes` does not join on its own: like any Arel condition, `where.has` leaves `references_values` alone, so `Post.includes(:author).where.has { author.name.eq('Ray') }` needs `.references(:authors)` to make Active Record eager load with a join.

##### Joins

```ruby
Post.joining { author }
# SELECT "posts".* FROM "posts"
# INNER JOIN "authors" ON "authors"."id" = "posts"."author_id"

Post.joining { [author.outer, comments] }
# SELECT "posts".* FROM "posts"
# LEFT OUTER JOIN "authors" ON "authors"."id" = "posts"."author_id"
# INNER JOIN "comments" ON "comments"."post_id" = "posts"."id"

Post.joining { author.comments }
# SELECT "posts".* FROM "posts"
# INNER JOIN "authors" ON "authors"."id" = "posts"."author_id"
# INNER JOIN "posts" "posts_authors_join" ON "posts_authors_join"."author_id" = "authors"."id"
# INNER JOIN "comments" ON "comments"."post_id" = "posts_authors_join"."id"

Post.joining { author.outer.comments.outer }
# SELECT "posts".* FROM "posts"
# LEFT OUTER JOIN "authors" ON "authors"."id" = "posts"."author_id"
# LEFT OUTER JOIN "posts" "posts_authors_join" ON "posts_authors_join"."author_id" = "authors"."id"
# LEFT OUTER JOIN "comments" ON "comments"."post_id" = "posts_authors_join"."id"

Post.joining { author.comments.outer }
# SELECT "posts".* FROM "posts"
# INNER JOIN "authors" ON "authors"."id" = "posts"."author_id"
# LEFT OUTER JOIN "posts" "posts_authors_join" ON "posts_authors_join"."author_id" = "authors"."id"
# LEFT OUTER JOIN "comments" ON "comments"."post_id" = "posts_authors_join"."id"

Post.joining { author.outer.posts }
# SELECT "posts".* FROM "posts"
# LEFT OUTER JOIN "authors" ON "authors"."id" = "posts"."author_id"
# LEFT OUTER JOIN "posts" "posts_authors" ON "posts_authors"."author_id" = "authors"."id"
#
# Everything joined below an outer join is an outer join, as with
# Post.left_joins(author: :posts).

Picture.joining { imageable.of(Post) }
# SELECT "pictures".* FROM "pictures"
# INNER JOIN "posts" ON "posts"."id" = "pictures"."imageable_id" AND "pictures"."imageable_type" = 'Post'

Picture.joining { imageable.of(Post).outer }
# SELECT "pictures".* FROM "pictures"
# LEFT OUTER JOIN "posts" ON "posts"."id" = "pictures"."imageable_id" AND "pictures"."imageable_type" = 'Post'
```

##### Subqueries

```ruby
Post.joins(:author).where.has {
  author.id.in Author.select(:id).where(name: 'Ray')
}
# SELECT "posts".* FROM "posts"
# INNER JOIN "authors" ON "authors"."id" = "posts"."author_id"
# WHERE "authors"."id" IN (
#   SELECT "authors"."id" FROM "authors"
#   WHERE "authors"."name" = 'Ray'
# )
```

##### Polymorphism

Given this polymorphism:

```ruby
# app/models/picture.rb
belongs_to :imageable, polymorphic: true

# app/models/post.rb
has_many :pictures, as: :imageable
```

The query might look like this:

```ruby
Picture.joining { imageable.of(Post) }
```

## How it works

`joining` hands Active Record a nested hash of the associations in the block. Inner joins are keyed by name, so Active Record merges them with its own `joins`. An outer join or a polymorphic `of` is keyed by a `BabySqueel::Join` value carrying the join type and the class; a prepend on `JoinDependency#build` turns those keys into join associations, one on `make_constraints` lets the outer type win over the inner tree, and one on `Reflection#join_scope` adds the polymorphic type condition.

An attribute of a joined association, `author.name`, has to use the alias Active Record gives that join. `Table#find_alias` builds the join dependency Active Record itself would build for the scope plus the chain, reads the table off the matching join association, and keeps it per chain for the block. Aliases are never computed by hand.

`where.has` passes the resulting Arel node to `where!`. A relation given to `in` or `not_in` goes through Active Record's handler for `where(column: relation)`.

Known limitation: an outer join of an association the relation already inner joins, `Post.joins(:author).joining { author.outer }`, is added as a second join. Active Record's `left_joins` would merge it into the inner join. The pending spec in `spec/integration/joining_spec.rb` describes it.

## What's what?

The following methods give you access to BabySqueel's DSL:

| BabySqueel    | Active Record Equivalent |
| ------------- | ------------------------ |
| `joining`     | `joins`                  |
| `where.has`   | `where`                  |

## Development

1. Pick an Active Record version to develop against, then export it: `export AR='~> 8.0.4'`. Unset, the newest version the gemspec allows is used.
2. Run `bin/setup` to install dependencies.
3. Run `rake` to run the specs.

Onliner to run the specs with different rails versions
```
gem install bundler:4.0.8

export AR='~> 8.0.4'; bin/setup; rake
export AR='~> 8.1.1'; bin/setup; rake
export AR='main'; bin/setup; rake

bundle exec rubocop
```

Two environment variables the specs read:

- `COVERAGE=1` writes a coverage report to `coverage/`. Off by default, so a plain run does not produce one.
- `UPDATE_SNAPSHOTS=1` records SQL snapshots. A missing snapshot fails the run instead of being recorded silently, so a renamed or new example needs this once. Snapshots with `variants:` are recorded per Active Record version, so run this for each version in the list; the unsuffixed key is for versions not in the list. Recording never removes keys; `rake snapshots:prune` does.

A snapshot is for SQL that has no plain Active Record equivalent, such as a polymorphic join. Everything else asserts `produce_sql(<the Active Record relation>)`, which also proves the gem does what Active Record does.

`bin/setup` rewrites `Gemfile.lock` for the given `AR`. A lock left on `AR=main` needs a Rails checkout that `bin/setup` makes; run `unset AR; bin/setup` before working without it.

You can also run `bin/console` to open up a prompt where you'll have access to some models to experiment with.

## Rails update

1. Update [baby_squeel.gemspec](baby_squeel.gemspec)
2. Add the version to test matrix [build.yml](.github/workflows/build.yml)
3. Update development section in the [README.md](README.md)
4. If the code has to branch on the Active Record version, put the check in [version_helper.rb](lib/baby_squeel/active_record/version_helper.rb) instead of inlining it. Collecting every version branch in one file makes them easy to find and drop once support for that version ends.
5. Add the version to every `match_sql_snapshot(variants: [...])` call whose SQL differs and record the snapshots with `UPDATE_SNAPSHOTS=1`
6. Run the specs with all supported versions
7. Add comment to the unreleased section in [CHANGELOG.md](CHANGELOG.md)

## Release

1. Set the version in [lib/baby_squeel/version.rb](lib/baby_squeel/version.rb), `x.y.z.internalN`
2. Move the unreleased section in [CHANGELOG.md](CHANGELOG.md) to a dated heading
3. Commit those two files as `release x.y.z.internalN`
4. `gem build baby_squeel.gemspec` and upload the gem to the gemserver; the file is git-ignored

The application bundles the gem from the gemserver; its `Gemfile.defaults.rb` carries a commented `path:` line to the sibling checkout that is opted into by swapping the comment.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
