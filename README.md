This is a fork of [baby_squeel](https://github.com/rzane/baby_squeel).
I aim to keep it compatible with Rails and publish my commits in case others find them useful.
However, I do not recommend using baby_squeel or this fork.
I plan to remove functions which I don’t need from this project without providing deprecations.

Release
```
update lib/baby_squeel/version.rb
update CHANGELOG.md

$ git add .
$ git commit -m "release x.y.z.internalA"
$ gem build baby_squeel.gemspec

upload gem to own gemserver
```

---

# BabySqueel 🐷

![Build](https://github.com/rocket-turtle/baby_squeel/workflows/Build/badge.svg)

Have you ever used the [Squeel](https://github.com/activerecord-hackery/squeel) gem? It's a really nice way to build complex queries. However, Squeel monkeypatches Active Record internals, because it was aimed at enhancing the existing API with the aim of inclusion into Rails. However, that inclusion never happened, and it left Squeel susceptible to breakage from arbitrary changes in Active Record, eventually burning out the maintainer.

BabySqueel provides a Squeel-like query DSL for Active Record while hopefully avoiding the majority of the version upgrade difficulties via a minimum of monkeypatching. :heart:

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'baby_squeel'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install baby_squeel

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

##### Selects

```ruby
Post.selecting { (id + 5).as('id_plus_five') }
# SELECT ("posts"."id" + 5) AS id_plus_five FROM "posts"

Post.selecting { id.sum }
# SELECT SUM("posts"."id") FROM "posts"

Post.joins(:author).selecting { [id, author.id] }
# SELECT "posts"."id", "authors"."id" FROM "posts"
# INNER JOIN "authors" ON "authors"."id" = "posts"."author_id"
```

##### Wheres

```ruby
Post.where.has { title.eq('My Post') }
# SELECT "posts".* FROM "posts"
# WHERE "posts"."title" = 'My Post'

Post.where.has { title.matches('My P%') }
# SELECT "posts".* FROM "posts"
# WHERE ("posts"."title" LIKE 'My P%')

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
# WHERE ("posts_authors"."title" LIKE '%fun%')
```

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
# INNER JOIN "posts" "posts_authors" ON "posts_authors"."author_id" = "authors"."id"

Post.joining { author.on(author.id.eq(author_id).or(author.name.eq(title))) }
# SELECT "posts".* FROM "posts"
# INNER JOIN "authors" ON ("authors"."id" = "posts"."author_id" OR "authors"."name" = "posts"."title")

Post.joining { |post| post.author.as('a').on { id.eq(post.author_id).or(name.eq(post.title)) } }
# SELECT "posts".* FROM "posts"
# INNER JOIN "authors" "a" ON ("a"."id" = "posts"."author_id" OR "a"."name" = "posts"."title")

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
Picture.
  joining { imageable.of(Post) }.
  selecting { imageable.of(Post).id }
```

##### Helpers

## What's what?

The following methods give you access to BabySqueel's DSL:

| BabySqueel    | Active Record Equivalent |
| ------------- | ------------------------ |
| `selecting`   | `select`                 |
| `joining`     | `joins`                  |
| `where.has`   | `where`                  |

## Development

1. Pick an Active Record version to develop against, then export it: `export AR=7.2.2`.
2. Run `bin/setup` to install dependencies.
3. Run `rake` to run the specs.

Onliner to run the specs with different rails versions
```
export AR='~> 7.1.5'; rm Gemfile.lock; bin/setup; rake
export AR='~> 7.2.2'; rm Gemfile.lock; bin/setup; rake
export AR='~> 8.0.2'; rm Gemfile.lock; bin/setup; rake
export AR='main'; rm Gemfile.lock; bin/setup; rake
```

You can also run `bin/console` to open up a prompt where you'll have access to some models to experiment with.

## Rails update

1. Update [baby_squeel.gemspec](baby_squeel.gemspec)
2. Add the version to test matrix [build.yml](.github/workflows/build.yml)
3. Update development section in the [README.md](README.md)
4. If you need to change the code consider to add a version check methode in [version_helper.rb](lib/baby_squeel/active_record/version_helper.rb)
5. Run the specs with all supported versions
6. Add comment to the unreleased section in [CHANGELOG.md](CHANGELOG.md)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rocket-turtle/baby_squeel.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
