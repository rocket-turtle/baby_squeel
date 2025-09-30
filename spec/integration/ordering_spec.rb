require 'spec_helper'

describe '#ordering' do
  it 'orders using arel' do
    relation = Post.ordering { title.desc }
    expect(relation).to match_sql_snapshot
  end

  it 'orders using multiple arel columns' do
    relation = Post.ordering {
      [title.desc, published_at.asc]
    }

    expect(relation).to match_sql_snapshot
  end

  it 'orders on an aggregates' do
    relation = Post.group('"posts"."id"').ordering {
      id.count.desc
    }

    expect(relation).to match_sql_snapshot
  end

  it 'orders using operations' do
    relation = Post.joins(:author).ordering {
      (author.id - id).desc
    }

    expect(relation).to match_sql_snapshot
  end

  it 'orders on an aliased table' do
    relation = Post.joins(author: :posts).ordering {
      author.posts.id
    }

    expect(relation).to match_sql_snapshot
  end
end
